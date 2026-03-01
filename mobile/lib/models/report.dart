import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

@freezed
sealed class Report with _$Report {
  const factory Report({
    required String id,
    required String reporterId,
    String? messageId,
    required String reason,
    @Default('pending') String status,
    required DateTime createdAt,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) =>
      _$ReportFromJson(json);
}
