import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:t_utils/t_utils.dart';
import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import '../../../features/shop/models/product_model.dart';
import '../../../features/shop/models/product_variants_model.dart';
import '../../../utils/constants/text_strings.dart';
import '../authentication/authentication_repository.dart';
import 'product_repository.dart';

/// Katalog uçları (`products`).
///
/// 🔴 **Fiyat kullanıcıya göre çözülür.** Oturum açıksa isteğe `userId`
/// eklenir; sunucu o kullanıcının yönetici tarafından atanmış fiyat kategorisine
/// (`PriceCategory`) göre fiyat döndürür. Misafirde liste fiyatı gelir. Bu
/// parametre düşerse bayiye perakende fiyatı gösterilir.
///
/// 🔴 **`products/{id}/variants` DİZİ DEĞİL NESNE döndürür.** Web'de varyantların
/// hiç görünmemesinin sebebi buydu. Normalleştirme [ProductVariantsModel] içinde
/// yapılır; hata ya da varyantsız üründe `hasVariants:false` boş model döner,
/// böylece ekran seçiciyi sessizce gizler.
class ApiProductRepository extends TApiRepositoryController<ProductModel>
    implements ProductRepository {
  static ApiProductRepository get instance => Get.find();

  ApiProductRepository()
      : super(
          fromJson: (json) => ProductModel.fromJson(
            json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
            json,
          ),
          toJson: (item) => item.toJson(),
          getId: (item) => item.id,
        );

  @override
  String getEndpoint() => 'products';

  /// Tek istekte çekilen katalog tavanı — aktif ürün sayısının ÜSTÜNDE
  /// tutulmalı.
  static const int _catalogPageSize = 20000;

  /// 🔴 **Kullanıcıya özel fiyat.** Oturum açıksa sunucu, kullanıcının
  /// yönetici tarafından atanmış fiyat kategorisine (`PriceCategory`) göre
  /// fiyat döndürür; misafirde liste fiyatı gelir. [url]'ye `userId`'yi doğru
  /// ayraçla (`?`/`&`) ekler. Bu parametre düşerse bayiye perakende fiyatı
  /// gösterilir.
  String _withUserPricing(String url) {
    final userId = Get.isRegistered<AuthenticationRepository>()
        ? AuthenticationRepository.instance.getUserID
        : '';
    if (userId.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}userId=${Uri.encodeQueryComponent(userId)}';
  }

  @override
  Future<String> addItem(ProductModel item) async {
    try {
      final response = await dio.post(
        getEndpoint(),
        data: item.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['Success'] == true) {
          return data['Data']['ProductId'] ?? '';
        } else {
          throw Exception(data['Message'] ?? 'Failed to create product');
        }
      } else {
        throw Exception('Failed to create product: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<List<ProductModel>> fetchAllItems() async {
    try {
      // Katalog tek istekte çekiliyor. Sunucu 'ORDER BY createdat DESC'
      // sıralıyor ve pageSize'a üst sınır koymuyor: bu değer AKTİF ürün
      // sayısının üstünde kalmalı, yoksa en ESKİ ürünler sessizce kesilir
      // (web'de tam bu yüzden Foral'in tamamı kaybolmuştu).
      final response = await dio.get(
          _withUserPricing('${getEndpoint()}?pageSize=$_catalogPageSize&isActive=true'));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final List<dynamic> productsJson = data['Data'] ?? [];
          return productsJson
              .map((json) => ProductModel.fromJson(
                    json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
                    json as Map<String, dynamic>,
                  ))
              .toList();
        } else {
          throw Exception(data['Message'] ?? 'Failed to fetch products');
        }
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  /// [categoryId] altındaki ürünleri getirir. Ürün listesi yanıtı ürün başına
  /// kategori kimliği taşımadığı için süzme **sunucuda**, `categoryId` sorgu
  /// parametresiyle yapılmalı — istemcide süzmeye kalkmak boş liste verir.
  /// Sayfalamayı destekler; mağaza kategoriyi tümden değil parça parça
  /// çekebilir.
  Future<List<ProductModel>> fetchProductsByCategory(String categoryId, {int page = 1, int pageSize = 1000}) async {
    try {
      final response = await dio.get(
        _withUserPricing('${getEndpoint()}?categoryId=${Uri.encodeQueryComponent(categoryId)}&isActive=true&page=$page&pageSize=$pageSize'),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final List<dynamic> productsJson = data['Data'] ?? [];
          return productsJson
              .map((json) => ProductModel.fromJson(
                    json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
                    json as Map<String, dynamic>,
                  ))
              .toList();
        } else {
          throw Exception(data['Message'] ?? 'Failed to fetch category products');
        }
      } else {
        throw Exception('Failed to fetch category products: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<List<ProductModel>> fetchPaginatedItems(int limit) async {
    try {
      // isActive=true: musteriye yalnizca aktif urun gosteriliyor. Filtresiz
      // istek tum tabloyu tarayip limit'e sigmayanlari kesiyordu.
      final response = await dio
          .get(_withUserPricing('${getEndpoint()}?page=1&pageSize=$limit&isActive=true'));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final List<dynamic> productsJson = data['Data'] ?? [];
          return productsJson
              .map((json) => ProductModel.fromJson(
                    json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
                    json as Map<String, dynamic>,
                  ))
              .toList();
        } else {
          throw Exception(data['Message'] ?? 'Failed to fetch products');
        }
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<List<ProductModel>> fetchPaginatedItemsWithPageAndLimit(
      int page, int limit) async {
    try {
      final response =
          await dio.get(_withUserPricing('${getEndpoint()}?page=$page&pageSize=$limit&isActive=true'));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final List<dynamic> productsJson = data['Data'] ?? [];
          return productsJson
              .map((json) => ProductModel.fromJson(
                    json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
                    json as Map<String, dynamic>,
                  ))
              .toList();
        } else {
          throw Exception(data['Message'] ?? 'Failed to fetch products');
        }
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<ProductModel> fetchSingleItem(String id) async {
    try {
      final response = await dio.get(_withUserPricing('${getEndpoint()}/$id'));

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final d = data['Data'] as Map<String, dynamic>;
          return ProductModel.fromJson(d['id']?.toString() ?? id, d);
        } else {
          throw Exception(data['Message'] ?? 'Failed to fetch product');
        }
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<void> updateItem(ProductModel item) async {
    try {
      final encodedId = Uri.encodeComponent(item.id);
      final data = Map<String, dynamic>.from(item.toJson());
      data.remove('ProductId');

      final response = await dio.put(
        '${getEndpoint()}/$encodedId',
        data: data,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final d = response.data;
        throw Exception(d['Message'] ?? 'Failed to update product');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<void> updateItemRecord(ProductModel item) async {
    try {
      return await updateItem(item);
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    try {
      final product = await fetchSingleItem(id);

      final updatedMap = {
        ...product.toJson(),
        ...json,
      };

      final updatedProduct = ProductModel.fromJson(id, updatedMap);

      await updateItem(updatedProduct);
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> deleteItem(ProductModel item) async {
    try {
      final response = await dio.delete('${getEndpoint()}/${item.id}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        final data = response.data;
        throw Exception(data['Message'] ?? 'Failed to delete product');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<List<ProductModel>> getAllRetailerProducts(String retailerId) async {
    try {
      final response = await dio.get('${getEndpoint()}?retailerId=$retailerId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final List<dynamic> productsJson = data['Data'] ?? [];
          return productsJson
              .map((json) => ProductModel.fromJson(
                    json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
                    json as Map<String, dynamic>,
                  ))
              .toList();
        } else {
          throw Exception(data['Message'] ?? 'Failed to fetch retailer products');
        }
      } else {
        throw Exception('Failed to fetch retailer products: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await dio
          .get('${getEndpoint()}?search=$query&pageSize=5&isActive=true');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['Success'] == true) {
          final List<dynamic> productsJson = data['Data'] ?? [];
          return productsJson
              .map((json) => ProductModel.fromJson(
                    json['id']?.toString() ?? json['ProductId']?.toString() ?? '',
                    json as Map<String, dynamic>,
                  ))
              .take(5)
              .toList();
        } else {
          throw Exception(data['Message'] ?? 'Failed to search products');
        }
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.somethingWentWrong.tr;
    }
  }

  /// Fetch the Model (Design) + Color (Renk) variant tree for [productId].
  /// Web'deki `getVariants(id)` → `/products/{id}/variants` karşılığı.
  ///
  /// 🔴 Uç **dizi değil nesne** döndürür; normalleştirme
  /// [ProductVariantsModel.fromJson] içindedir. Ürünün varyantı yoksa ya da
  /// çağrı başarısızsa `hasVariants:false` boş model döner, böylece arayüz
  /// seçiciyi sessizce gizler — hata penceresi açmaz.
  Future<ProductVariantsModel> getProductVariants(String productId) async {
    try {
      final response =
          await dio.get(_withUserPricing('${getEndpoint()}/$productId/variants'));

      if (response.statusCode == 200 && isSuccess(response.data)) {
        final data = dataOf(response.data);
        if (data is Map) {
          return ProductVariantsModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return ProductVariantsModel.empty();
    } catch (_) {
      return ProductVariantsModel.empty();
    }
  }

  /// Renk kutucuklarını boyamak için kullanılan `renk kodu → hex` eşlemesi.
  /// Web'deki `getColors()` → `/products/colors` karşılığı. Hatada boş eşleme
  /// döner, çağıran varsayılan renge düşebilsin.
  Future<Map<String, String>> getProductColors() async {
    try {
      final response = await dio.get('${getEndpoint()}/colors');

      if (response.statusCode == 200 && isSuccess(response.data)) {
        final data = dataOf(response.data);
        if (data is Map) {
          return data.map((key, value) =>
              MapEntry(key.toString(), value?.toString() ?? ''));
        }
        // Some backends return a list of {code/name, hex} objects instead of a map.
        if (data is List) {
          final result = <String, String>{};
          for (final item in data) {
            if (item is Map) {
              final code = (item['Code'] ?? item['code'] ?? item['Name'] ?? item['name'])?.toString();
              final hex = (item['Hex'] ?? item['hex'] ?? item['Value'] ?? item['value'] ?? item['Color'] ?? item['color'])?.toString();
              if (code != null && code.isNotEmpty && hex != null && hex.isNotEmpty) {
                result[code] = hex;
              }
            }
          }
          return result;
        }
      }
      return <String, String>{};
    } catch (_) {
      return <String, String>{};
    }
  }
}
