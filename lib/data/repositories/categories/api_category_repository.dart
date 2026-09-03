/// Kategori ağacı (`categories`).
///
/// ⚠️ `fetchAllItems()` ağacı **düzleştirerek** döndürür: kökler ve tüm alt
/// dallar tek listede, her biri kendi `subCategories`'ini taşımaya devam eder.
/// Ağaç çizen ekranlar kökleri `parentId` boş olanlardan seçmeli; ağaç
/// derinliği sabit değildir (4 seviyeye kadar iniyor).
library;

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/shop/models/category_model.dart';
import 'category_repository.dart';

class ApiCategoryRepository extends TApiRepositoryController<CategoryModel>
    implements CategoryRepository {
  static ApiCategoryRepository get instance => Get.find();

  ApiCategoryRepository()
      : super(
          fromJson: (json) => CategoryModel.fromJson(json['id']?.toString() ?? '', json),
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
        );

  @override
  String getEndpoint() => 'categories';

  bool isAdmin = true;

  @override
  Future<List<CategoryModel>> fetchAllItems() async {
    try {
      // print('[CategoryRepository] GET ${getEndpoint()} (isAdmin=$isAdmin)');
      final response = await dio.get(
        getEndpoint(),
        queryParameters: {'isAdmin': isAdmin},
      );

      if (response.data['Success'] == true) {
        final List<dynamic> dataList = response.data['Data'] as List<dynamic>;
        // print('[CategoryRepository] Response OK, ${dataList.length} root categories received');

        final List<CategoryModel> flatList = [];

        void flatten(CategoryModel category, int depth) {
          // print('[CategoryRepository] ${'  ' * depth}- ${category.name} (id=${category.id}, parentId=${category.parentId})');
          flatList.add(category);
          for (final sub in category.subCategories) {
            flatten(sub, depth + 1);
          }
        }

        for (var item in dataList) {
          final json = item as Map<String, dynamic>;
          flatten(CategoryModel.fromJson(json['Id']?.toString() ?? '', json), 0);
        }

        flatList.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        // print('[CategoryRepository] Flattened to ${flatList.length} total categories');
        return flatList;
      } else {
        // print('[CategoryRepository] Request failed: ${response.data['Message']}');
        throw response.data['Message'] ?? 'Failed to fetch categories';
      }
    } catch (e) {
      // print('[CategoryRepository] Error fetching categories: $e');
      throw handleException(e);
    }
  }

  @override
  Future<CategoryModel> fetchSingleItem(String id) async {
    try {
      final response = await dio.get(
        '${getEndpoint()}/$id',
        queryParameters: {'isAdmin': isAdmin},
      );

      if (response.data['Success'] == true) {
        return fromJson(response.data['Data'] as Map<String, dynamic>);
      } else {
        throw handleException("${response.data['Message'] ?? 'Failed to fetch category'}");
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<String> addItem(CategoryModel item) async {
    try {
      final response = await dio.post(getEndpoint(), data: item.toJson());

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to add category';
      } else {
        return response.data['Data']['Id'].toString();
      }
    } catch (e) {
      // print(e);
      throw handleException(e);
    }
  }

  @override
  Future<String> addCategory(CategoryModel category) async {
    try {
      return await addItem(category);
    } catch (e) {
      // print('Error adding category ${category.name}: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateItem(CategoryModel item) async {
    try {
      final response = await dio.put('${getEndpoint()}/${item.id}', data: item.toJson());

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to update item';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    try {
      final category = await fetchSingleItem(id);

      final updatedMap = {...category.toJson(), ...json};
      final updatedCategory = CategoryModel.fromJson(id, updatedMap);

      final response = await dio.put('${getEndpoint()}/$id', data: updatedCategory.toJson());

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to update item';
      }
    } catch (e) {
      // print(e);
      throw handleException(e);
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await updateItemRecord(category);
  }

  @override
  Future<void> saveCategoryTree(CategoryModel category) async {
    try {
      if (category.id.isEmpty) {
        final newId = await addItem(category);
        category.id = newId;
      } else {
        await updateItem(category);
      }
    } catch (e) {
      // print("Error saving category ${category.name}: $e");
      rethrow;
    }
  }

  @override
  Future<List<CategoryModel>> searchProducts(String query) async {
    try {
      final response = await dio.get(
        getEndpoint(),
        queryParameters: {'isAdmin': isAdmin, 'search': query.toLowerCase(), 'limit': 5},
      );

      if (response.data['Success'] == true) {
        final List<dynamic> dataList = response.data['Data'] as List<dynamic>;
        return dataList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      } else {
        return [];
      }
    } catch (e) {
      // print('Error searching categories: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryModel>> fetchPaginatedItems(int limit) async {
    try {
      pageSize = limit;

      final response = await dio.get(
        getEndpoint(),
        queryParameters: {'isAdmin': isAdmin, 'page': currentPage, 'pageSize': pageSize},
      );

      if (response.data['Success'] == true) {
        final List<dynamic> dataList = response.data['Data'] as List<dynamic>;
        totalCount = response.data['TotalCount'] ?? 0;
        currentPage++;
        return dataList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch items';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> deleteItem(CategoryModel item) async {
    try {
      final response = await dio.delete('${getEndpoint()}/${getId(item)}');

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to delete item';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
