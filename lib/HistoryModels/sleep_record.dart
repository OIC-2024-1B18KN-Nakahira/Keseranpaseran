import 'history_record.dart';
import 'record_type.dart';

class SleepRecord extends HistoryRecord {
  final Duration duration;

  SleepRecord({
    required DateTime date,
    required this.duration,
  }) : super(date: date, type: RecordType.sleep);
}