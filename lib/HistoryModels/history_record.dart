import 'record_type.dart';

abstract class HistoryRecord {
  final DateTime date;
  final RecordType type;

  HistoryRecord({
    required this.date,
    required this.type,
  });
}