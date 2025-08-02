import 'package:flutter_riverpod/flutter_riverpod.dart';

final ageProvider = StateProvider<int>((ref) => 0);

final pregnantProvider = StateProvider<bool>((ref) => false);