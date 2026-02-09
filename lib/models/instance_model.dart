import 'package:json_annotation/json_annotation.dart';

part 'instance_model.g.dart';

@JsonSerializable()
class InstanceModel {
  final String id;
  String name;
  String minecraftVersion;
  String loaderType;
  String loaderVersion;
  String javaPath;
  int allocatedMemory;
  List<String> jvmArguments;
  List<String> gameArguments;
  final String instanceDir;
  String iconPath;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;
  
  String userId;
  String accessToken;
  String userType;
  String? assetIndex;
  bool isCrashed;
  String crashReason;
  DateTime? lastCrashTime;
  List<Map<String, dynamic>> gameErrors;
  List<String> onlinePlayers;
  String serverAddress;
  bool isConnectedToServer;
  bool isGameReady;
  DateTime? lastReadyTime;
  double resourceLoadingProgress;
  
  InstanceModel({
    required this.id,
    required this.name,
    required this.minecraftVersion,
    required this.loaderType,
    required this.loaderVersion,
    required this.javaPath,
    required this.allocatedMemory,
    required this.jvmArguments,
    required this.gameArguments,
    required this.instanceDir,
    required this.iconPath,
    this.isActive = false,
    required this.createdAt,
    required this.updatedAt,
    this.userId = '',
    this.accessToken = '',
    this.userType = 'mojang',
    this.assetIndex,
    this.isCrashed = false,
    this.crashReason = '',
    this.lastCrashTime,
    this.gameErrors = const [],
    this.onlinePlayers = const [],
    this.serverAddress = '',
    this.isConnectedToServer = false,
    this.isGameReady = false,
    this.lastReadyTime,
    this.resourceLoadingProgress = 0.0,
  });
  
  factory InstanceModel.fromJson(Map<String, dynamic> json) => _$InstanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$InstanceModelToJson(this);
  
  InstanceModel copyWith({
    String? id,
    String? name,
    String? minecraftVersion,
    String? loaderType,
    String? loaderVersion,
    String? javaPath,
    int? allocatedMemory,
    List<String>? jvmArguments,
    List<String>? gameArguments,
    String? instanceDir,
    String? iconPath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? accessToken,
    String? userType,
    String? assetIndex,
    bool? isCrashed,
    String? crashReason,
    DateTime? lastCrashTime,
    List<Map<String, dynamic>>? gameErrors,
    List<String>? onlinePlayers,
    String? serverAddress,
    bool? isConnectedToServer,
    bool? isGameReady,
    DateTime? lastReadyTime,
    double? resourceLoadingProgress,
  }) {
    return InstanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      minecraftVersion: minecraftVersion ?? this.minecraftVersion,
      loaderType: loaderType ?? this.loaderType,
      loaderVersion: loaderVersion ?? this.loaderVersion,
      javaPath: javaPath ?? this.javaPath,
      allocatedMemory: allocatedMemory ?? this.allocatedMemory,
      jvmArguments: jvmArguments ?? this.jvmArguments,
      gameArguments: gameArguments ?? this.gameArguments,
      instanceDir: instanceDir ?? this.instanceDir,
      iconPath: iconPath ?? this.iconPath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      userType: userType ?? this.userType,
      assetIndex: assetIndex ?? this.assetIndex,
      isCrashed: isCrashed ?? this.isCrashed,
      crashReason: crashReason ?? this.crashReason,
      lastCrashTime: lastCrashTime ?? this.lastCrashTime,
      gameErrors: gameErrors ?? this.gameErrors,
      onlinePlayers: onlinePlayers ?? this.onlinePlayers,
      serverAddress: serverAddress ?? this.serverAddress,
      isConnectedToServer: isConnectedToServer ?? this.isConnectedToServer,
      isGameReady: isGameReady ?? this.isGameReady,
      lastReadyTime: lastReadyTime ?? this.lastReadyTime,
      resourceLoadingProgress: resourceLoadingProgress ?? this.resourceLoadingProgress,
    );
  }
}
