import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plate.dart';
import 'repository_providers.dart';

final platesProvider = AsyncNotifierProvider<PlatesNotifier, List<Plate>>(
  PlatesNotifier.new,
);

class PlatesNotifier extends AsyncNotifier<List<Plate>> {
  @override
  Future<List<Plate>> build() async {
    final plateRepo = ref.read(plateRepositoryProvider);
    return plateRepo.listPlates();
  }

  Future<void> claimPlate({
    required String plateNumber,
    String? stateOrRegion,
  }) async {
    final plateRepo = ref.read(plateRepositoryProvider);
    final plate = await plateRepo.claimPlate(
      plateNumber: plateNumber,
      stateOrRegion: stateOrRegion,
    );

    final current = state.value ?? [];
    state = AsyncData([...current, plate]);
  }

  Future<void> releasePlate(String id) async {
    final plateRepo = ref.read(plateRepositoryProvider);
    await plateRepo.releasePlate(id);

    final current = state.value ?? [];
    state = AsyncData(current.where((p) => p.id != id).toList());
  }
}
