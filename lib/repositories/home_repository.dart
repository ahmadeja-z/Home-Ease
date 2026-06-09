import 'package:flutter/foundation.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/models/banner_model.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/models/services_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeRepository {
  final supabaseInstance = Supabase.instance.client;

  Future<({List<ServicesCategoriesModel> categories, int totalCount})>
  getServicesCategories({
    int limit = 10,
    int offset = 0,
    String? search,
  }) {
    return guardNetworkCall(() async {
    var query = supabaseInstance.from('servicesCategories').select();

    if (search != null && search.isNotEmpty) {
      query = query.ilike('name', '%$search%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final List<dynamic> data = response.data as List<dynamic>;
    final int totalCount = response.count;

    final categories = data
        .map((e) => ServicesCategoriesModel.fromMap(e as Map<String, dynamic>))
        .toList();

    if (kDebugMode) {
      print(
        'JobsRepository - servicesCategories: fetched ${categories.length} categories (Total: $totalCount) [limit: $limit, offset: $offset]',
      );
    }

    return (categories: categories, totalCount: totalCount);
    });
  }

  Future<({List<ServicesModel> services, int totalCount})> getServices({
    int limit = 10,
    int offset = 0,
    String? search,
    String? categoryId,
  }) {
    return guardNetworkCall(() async {
    var query = supabaseInstance
        .from('services')
        .select('*, servicesCategories(name)');

    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final List<dynamic> data = response.data as List<dynamic>;
    final int totalCount = response.count;

    final services = data.map((e) {
      final map = e as Map<String, dynamic>;
      final categoryData = map['servicesCategories'] as Map<String, dynamic>?;
      map['categoryTitle'] = categoryData?['name'] ?? '';
      final model = ServicesModel.fromJson(map);
      if (kDebugMode) {
        print('ServicesRepository - fetched service: $model');
      }
      return model;
    }).toList();

    return (services: services, totalCount: totalCount);
    });
  }

  Future<({List<BannerModel> banners, int totalCount})> getBanners({
    int limit = 10,
    int offset = 0,
    String? search,
  }) {
    return guardNetworkCall(() async {
    try {
      var query = supabaseInstance.from('banners').select('*');

      // Apply search filter if provided
      if (search != null && search.isNotEmpty) {
        query = query.or('title.ilike.%$search%,subtitle.ilike.%$search%');
      }

      // Multi-level ordering for consistent results:
      // 1. Priority (highest first)
      // 2. Created at (newest first for same priority)
      // 3. ID (tiebreaker for exact same timestamp)
      final response = await query
          .order('priority', ascending: false)
          .order('created_at', ascending: false)
          .order('id', ascending: true)
          .range(offset, offset + limit - 1)
          .count(CountOption.exact);

      final List<dynamic> data = response.data as List<dynamic>;
      final int totalCount = response.count;

      if (kDebugMode) {
        print('ContentRepository - RAW Supabase response:');
        for (final row in data) {
          print(row);
        }
      }

      final banners = data
          .map((e) => BannerModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print(
          'ContentRepository - getBanners: fetched ${banners.length} banners '
          '(Total: $totalCount) [limit: $limit, offset: $offset] [search: $search]',
        );
      }

      return (banners: banners, totalCount: totalCount);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch banners: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching banners: $e');
    }
    });
  }
}
