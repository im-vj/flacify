import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/radio_station.dart';
import 'navidrome_provider.dart';

final radioStationsProvider = FutureProvider<List<RadioStation>>((ref) async {
  final service = ref.watch(navidromeServiceProvider);
  if (service == null) return [];
  return service.getInternetRadioStations();
});
