import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_repository.dart';
import 'user_admin_model.dart';

final usersRepositoryProvider = Provider((ref) => UsersRepository());

final usersProvider = StreamProvider<List<UserAdminModel>>((ref) {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUsersStream();
});

final userStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final repository = ref.watch(usersRepositoryProvider);
  return await repository.getUserStats(userId);
});

final userOrdersProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final repository = ref.watch(usersRepositoryProvider);
  return repository.getUserOrdersStream(userId);
});
