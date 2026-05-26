import 'package:flutter/foundation.dart';
import 'package:homeease/models/services_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectedCategoryRepository {
  final supabaseInstance = Supabase.instance.client;

  Future<List<ServicesModel>> getServicesByCategory(String categoryId) async {
    try {
      final response = await supabaseInstance
          .from('services')
          .select('*, servicesCategories(name)')
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      final services = data.map((e) {
        final map = e as Map<String, dynamic>;
        final categoryData = map['servicesCategories'] as Map<String, dynamic>?;
        map['categoryTitle'] = categoryData?['name'] ?? '';
        final model = ServicesModel.fromJson(map);
        if (kDebugMode) {
          print('SelectedCategoryRepository - fetched service: $model');
        }
        return model;
      }).toList();

      if (kDebugMode) {
        print(
          'SelectedCategoryRepository - fetched ${services.length} services for category: $categoryId',
        );
      }

      return services;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch services: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error fetching services: $e');
    }
  }
}
