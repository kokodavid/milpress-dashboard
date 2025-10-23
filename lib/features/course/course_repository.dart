import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'course_models.dart';

// Providers
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final client = Supabase.instance.client;
  return CourseRepository(client);
});

// Total count of courses
final coursesCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.countCourses();
});

final coursesListProvider = FutureProvider.family<List<Course>, CoursesQuery?>((ref, query) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchCourses(query: query);
});

final courseByIdProvider = FutureProvider.family<Course?, String>((ref, id) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.fetchCourseById(id);
});

// Mutation notifiers
class CreateCourseController extends StateNotifier<AsyncValue<Course?>> {
  final CourseRepository _repo;
  CreateCourseController(this._repo) : super(const AsyncData<Course?>(null));

  Future<Course?> create(CourseCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createCourse(data);
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createCourseProvider = StateNotifierProvider<CreateCourseController, AsyncValue<Course?>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return CreateCourseController(repo);
});

class UpdateCourseController extends StateNotifier<AsyncValue<void>> {
  final CourseRepository _repo;
  UpdateCourseController(this._repo) : super(const AsyncData(null));

  Future<void> update(String id, CourseUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateCourse(id, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateCourseProvider = StateNotifierProvider<UpdateCourseController, AsyncValue<void>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return UpdateCourseController(repo);
});

class DeleteCourseController extends StateNotifier<AsyncValue<void>> {
  final CourseRepository _repo;
  DeleteCourseController(this._repo) : super(const AsyncData(null));

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteCourse(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteCourseProvider = StateNotifierProvider<DeleteCourseController, AsyncValue<void>>((ref) {
  final repo = ref.watch(courseRepositoryProvider);
  return DeleteCourseController(repo);
});

// Query object for flexibility (filtering, sorting, pagination)
class CoursesQuery {
  final String? search;
  final bool? locked;
  final int? level;
  final String? type;
  final int? limit;
  final int? offset;
  final String? orderBy; // column name
  final bool ascending;

  const CoursesQuery({
    this.search,
    this.locked,
    this.level,
    this.type,
    this.limit,
    this.offset,
    this.orderBy,
    this.ascending = true,
  });
}

class CourseRepository {
  final SupabaseClient _client;
  CourseRepository(this._client);

  static const String table = 'courses';

  // Read list
  Future<List<Course>> fetchCourses({CoursesQuery? query}) async {
    dynamic qb = _client.from(table).select();

    if (query?.search != null && query!.search!.isNotEmpty) {
      // ilike title/description for search
      qb = qb.or('title.ilike.%${query.search!}%,description.ilike.%${query.search!}%');
    }
    if (query?.locked != null) {
      qb = qb.eq('locked', query!.locked!);
    }
    if (query?.level != null) {
      qb = qb.eq('level', query!.level!);
    }
    if (query?.type != null) {
      qb = qb.eq('type', query!.type!);
    }
    if (query?.orderBy != null) {
      qb = qb.order(query!.orderBy!, ascending: query.ascending);
    } else {
      qb = qb.order('created_at', ascending: false);
    }
    if (query?.limit != null) {
      qb = qb.limit(query!.limit!);
    }
    if (query?.offset != null) {
      final end = (query!.offset! + (query.limit ?? 50)) - 1;
      qb = qb.range(query.offset!, end);
    }

    final List data = await qb;
    return data.map((e) => Course.fromMap(e as Map<String, dynamic>)).toList();
  }

  // Read single
  Future<Course?> fetchCourseById(String id) async {
    final data = await _client.from(table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Course.fromMap(data);
  }

  // Create
  Future<Course> createCourse(CourseCreate input) async {
    final List data = await _client.from(table).insert(input.toInsertMap()).select();
    return Course.fromMap(data.first as Map<String, dynamic>);
  }

  // Update
  Future<void> updateCourse(String id, CourseUpdate update) async {
    await _client.from(table).update(update.toUpdateMap()).eq('id', id);
  }

  // Delete
  Future<void> deleteCourse(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  // Count
  Future<int> countCourses() async {
    final List data = await _client.from(table).select('id');
    return data.length;
  }
}
