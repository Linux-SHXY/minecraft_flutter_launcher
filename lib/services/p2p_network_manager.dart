import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';

enum NetworkStatus { disconnected, connecting, connected, connectionFailed, discovering, discoveryFailed }

class P2PNode {
  final String address;
  final int port;
  final String name;
  final String version;
  final int ping;
  P2PNode({required this.address, required this.port, required this.name, required this.version, required this.ping});
  factory P2PNode.fromJson(Map<String, dynamic> json) => P2PNode(address: json['address'], port: json['port'], name: json['name'], version: json['version'], ping: json['ping']);
  Map<String, dynamic> toJson() => {'address': address, 'port': port, 'name': name, 'version': version, 'ping': ping};
}

class P2PNetworkManager {
  final Dio _dio = Dio();
  final StreamController<NetworkStatus> _p2pController = StreamController<NetworkStatus>.broadcast();
  final StreamController<List<P2PNode>> _nodesController = StreamController<List<P2PNode>>.broadcast();
  static const int _broadcastPort = 19132;
  static const int _listenPort = 19133;
  static const Duration _discoveryTimeout = Duration(seconds: 5);
  final List<P2PNode> _nodes = [];
  Stream<NetworkStatus> get networkStatusStream => _p2pController.stream;
  Stream<List<P2PNode>> get nodesStream => _nodesController.stream;

  Future<void> discoverPeers() async {
    _p2pController.add(NetworkStatus.discovering);
    _nodes.clear();
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _listenPort, reusePort: true);
      socket.broadcastEnabled = true;
      await _sendBroadcastMessage(socket);
      await _listenForResponses(socket);
      socket.close();
      _nodesController.add(List.from(_nodes));
      _p2pController.add(NetworkStatus.connected);
    } catch (e) {
      print('Failed to discover peers: $e');
      _p2pController.add(NetworkStatus.discoveryFailed);
    }
  }

  Future<void> _sendBroadcastMessage(RawDatagramSocket socket) async {
    final broadcastMessage = jsonEncode({'type': 'discover', 'version': '1.0.0', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    final messageBytes = Uint8List.fromList(broadcastMessage.codeUnits);
    final broadcastAddresses = await _getBroadcastAddresses();
    for (final address in broadcastAddresses) {
      socket.send(messageBytes, address, _broadcastPort);
      print('Sent broadcast to $address:$_broadcastPort');
    }
  }

  Future<List<InternetAddress>> _getBroadcastAddresses() async {
    final addresses = <InternetAddress>[];
    final interfaces = await NetworkInterface.list();
    for (final interface in interfaces) {
      final isLoopback = interface.addresses.any((addr) => addr.isLoopback);
      if (!isLoopback && interface.addresses.isNotEmpty) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final broadcast = '${parts[0]}.${parts[1]}.${parts[2]}.255';
              addresses.add(InternetAddress(broadcast));
            }
          }
        }
      }
    }
    addresses.add(InternetAddress('255.255.255.255'));
    return addresses;
  }

  Future<void> _listenForResponses(RawDatagramSocket socket) async {
    final stopwatch = Stopwatch()..start();
    final responseCompleter = Completer<void>();
    final timeoutTimer = Timer(_discoveryTimeout, () { if (!responseCompleter.isCompleted) responseCompleter.complete(); });
    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) _handleDatagram(datagram, stopwatch.elapsedMilliseconds);
      }
    });
    await responseCompleter.future;
    timeoutTimer.cancel();
  }

  void _handleDatagram(Datagram datagram, int elapsedTime) {
    try {
      final message = String.fromCharCodes(datagram.data);
      final jsonMsg = jsonDecode(message) as Map<String, dynamic>;
      if (jsonMsg['type'] == 'discover_response') {
        final node = P2PNode(address: datagram.address.address, port: jsonMsg['port'] as int, name: jsonMsg['name'] as String, version: jsonMsg['version'] as String, ping: elapsedTime);
        if (!_nodes.any((n) => n.address == node.address && n.port == node.port)) {
          _nodes.add(node);
          print('Discovered node: ${node.name} at ${node.address}:${node.port} (ping: ${node.ping}ms)');
        }
      }
    } catch (e) {
      print('Failed to handle datagram: $e');
    }
  }

  final Map<String, Socket> _activeConnections = {};
  Future<void> connectToPeer(String peerAddress) async {
    _p2pController.add(NetworkStatus.connecting);
    try {
      final addressParts = peerAddress.split(':');
      final address = addressParts[0];
      final port = addressParts.length > 1 ? int.parse(addressParts[1]) : 8080;
      final socket = await Socket.connect(address, port, timeout: const Duration(seconds: 5));
      print('TCP connection established with $peerAddress');
      final nodeInfo = await _exchangeNodeInfo(socket);
      print('Node info exchanged: ${nodeInfo.name} (${nodeInfo.version})');
      await _handleNATTraversal(socket, nodeInfo);
      await _establishSecureChannel(socket);
      _activeConnections[peerAddress] = socket;
      _startListeningToSocket(socket, peerAddress);
      _p2pController.add(NetworkStatus.connected);
      print('Successfully connected to peer: $peerAddress');
    } catch (e) {
      print('Failed to connect to peer: $peerAddress, error: $e');
      _p2pController.add(NetworkStatus.connectionFailed);
    }
  }

  Future<P2PNode> _exchangeNodeInfo(Socket socket) async {
    final completer = Completer<P2PNode>();
    final localNodeInfo = {'type': 'node_info', 'name': 'BAMCLauncher', 'version': '1.0.0', 'port': _listenPort, 'timestamp': DateTime.now().millisecondsSinceEpoch};
    final localInfoBytes = Uint8List.fromList(jsonEncode(localNodeInfo).codeUnits);
    socket.add(localInfoBytes);
    socket.listen((List<int> data) {
      try {
        final message = String.fromCharCodes(data);
        final jsonMsg = jsonDecode(message) as Map<String, dynamic>;
        if (jsonMsg['type'] == 'node_info') {
          final node = P2PNode(address: socket.remoteAddress.address, port: jsonMsg['port'] as int, name: jsonMsg['name'] as String, version: jsonMsg['version'] as String, ping: 0);
          completer.complete(node);
        }
      } catch (e) { completer.completeError(e); }
    }, onError: (error) { completer.completeError(error); }, cancelOnError: true);
    return completer.future;
  }

  Future<void> _handleNATTraversal(Socket socket, P2PNode nodeInfo) async {}
  Future<void> _establishSecureChannel(Socket socket) async {}
  void _startListeningToSocket(Socket socket, String peerAddress) {}
}
