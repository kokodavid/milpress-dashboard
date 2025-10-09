
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final loginStateProvider = StateNotifierProvider<LoginStateNotifier, AsyncValue<void>>((ref) {
	final repo = ref.watch(authRepositoryProvider);
	return LoginStateNotifier(repo);
});

class LoginStateNotifier extends StateNotifier<AsyncValue<void>> {
	final AuthRepository _repo;
	LoginStateNotifier(this._repo) : super(const AsyncData(null));

	Future<void> login(String email, String password) async {
		state = const AsyncLoading();
			try {
				final response = await _repo.login(email: email, password: password);
				if (response.user == null) {
					state = AsyncError('Invalid credentials', StackTrace.current);
				} else {
					state = const AsyncData(null);
				}
			} catch (e, st) {
				state = AsyncError(e, st);
			}
	}
}
class AuthRepository {
	Future<AuthResponse> login({required String email, required String password}) async {
		return await Supabase.instance.client.auth.signInWithPassword(
			email: email,
			password: password,
		);
	}
}
