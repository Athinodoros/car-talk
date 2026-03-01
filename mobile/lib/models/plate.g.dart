// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Plate _$PlateFromJson(Map<String, dynamic> json) => _Plate(
  id: json['id'] as String,
  userId: json['userId'] as String?,
  plateNumber: json['plateNumber'] as String,
  stateOrRegion: json['stateOrRegion'] as String?,
  claimedAt: json['claimedAt'] == null
      ? null
      : DateTime.parse(json['claimedAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PlateToJson(_Plate instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'plateNumber': instance.plateNumber,
  'stateOrRegion': instance.stateOrRegion,
  'claimedAt': instance.claimedAt?.toIso8601String(),
  'isActive': instance.isActive,
  'createdAt': instance.createdAt.toIso8601String(),
};
