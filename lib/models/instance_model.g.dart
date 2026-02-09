// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstanceModel _$InstanceModelFromJson(Map<String, dynamic> json) =>
    InstanceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      minecraftVersion: json['minecraftVersion'] as String,
      loaderType: json['loaderType'] as String,
      loaderVersion: json['loaderVersion'] as String,
      javaPath: json['javaPath'] as String,
      allocatedMemory: (json['allocatedMemory'] as num).toInt(),
      jvmArguments: (json['jvmArguments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      gameArguments: (json['gameArguments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      instanceDir: json['instanceDir'] as String,
      iconPath: json['iconPath'] as String,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      userId: json['userId'] as String? ?? '',
      accessToken: json['accessToken'] as String? ?? '',
      userType: json['userType'] as String? ?? 'mojang',
      assetIndex: json['assetIndex'] as String?,
      isCrashed: json['isCrashed'] as bool? ?? false,
      crashReason: json['crashReason'] as String? ?? '',
      lastCrashTime: json['lastCrashTime'] == null
          ? null
          : DateTime.parse(json['lastCrashTime'] as String),
      gameErrors: (json['gameErrors'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      onlinePlayers: (json['onlinePlayers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      serverAddress: json['serverAddress'] as String? ?? '',
      isConnectedToServer: json['isConnectedToServer'] as bool? ?? false,
      isGameReady: json['isGameReady'] as bool? ?? false,
      lastReadyTime: json['lastReadyTime'] == null
          ? null
          : DateTime.parse(json['lastReadyTime'] as String),
      resourceLoadingProgress:
          (json['resourceLoadingProgress'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$InstanceModelToJson(InstanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'minecraftVersion': instance.minecraftVersion,
      'loaderType': instance.loaderType,
      'loaderVersion': instance.loaderVersion,
      'javaPath': instance.javaPath,
      'allocatedMemory': instance.allocatedMemory,
      'jvmArguments': instance.jvmArguments,
      'gameArguments': instance.gameArguments,
      'instanceDir': instance.instanceDir,
      'iconPath': instance.iconPath,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'userId': instance.userId,
      'accessToken': instance.accessToken,
      'userType': instance.userType,
      'assetIndex': instance.assetIndex,
      'isCrashed': instance.isCrashed,
      'crashReason': instance.crashReason,
      'lastCrashTime': instance.lastCrashTime?.toIso8601String(),
      'gameErrors': instance.gameErrors,
      'onlinePlayers': instance.onlinePlayers,
      'serverAddress': instance.serverAddress,
      'isConnectedToServer': instance.isConnectedToServer,
      'isGameReady': instance.isGameReady,
      'lastReadyTime': instance.lastReadyTime?.toIso8601String(),
      'resourceLoadingProgress': instance.resourceLoadingProgress,
    };
