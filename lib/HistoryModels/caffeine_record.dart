import 'history_record.dart';
import 'record_type.dart';

class CaffeineRecord extends HistoryRecord {
  final int mg;

  CaffeineRecord({
    required DateTime date,
    required this.mg,
  }) : super(date: date, type: RecordType.caffeine);
}