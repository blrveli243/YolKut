import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_repository.dart';
import '../nutrition/nutrition_provider.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

class ProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final repo = ref.read(profileRepositoryProvider);
    return await repo.fetchProfile();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue<Map<String, dynamic>>.loading().copyWithPrevious(state);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(data);
      final newProfile = await repo.fetchProfile();
      state = AsyncValue.data(newProfile);
      
      // Profil güncellendiğinde beslenme verilerini de yenile
      ref.invalidate(nutritionProvider);
    } catch (e, stack) {
      state = AsyncValue<Map<String, dynamic>>.error(e, stack).copyWithPrevious(state);
    }
  }

  Future<void> uploadPhoto(String filePath) async {
    state = const AsyncValue<Map<String, dynamic>>.loading().copyWithPrevious(state);
    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.uploadProfilePhoto(filePath);
      final newProfile = await repo.fetchProfile();
      state = AsyncValue.data(newProfile);
    } catch (e, stack) {
      state = AsyncValue<Map<String, dynamic>>.error(e, stack).copyWithPrevious(state);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Map<String, dynamic>>(() {
  return ProfileNotifier();
});
