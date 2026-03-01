import 'package:freezed_annotation/freezed_annotation.dart';

part 'plate.freezed.dart';
part 'plate.g.dart';

@freezed
sealed class Plate with _$Plate {
  const factory Plate({
    required String id,
    String? userId,
    required String plateNumber,
    String? stateOrRegion,
    DateTime? claimedAt,
    @Default(true) bool isActive,
    required DateTime createdAt,
  }) = _Plate;

  factory Plate.fromJson(Map<String, dynamic> json) => _$PlateFromJson(json);
}
