import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides the singleton [SupabaseClient] to the Riverpod tree.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Convenience: current authenticated user, or null.
final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(supabaseClientProvider).auth.currentUser,
);
