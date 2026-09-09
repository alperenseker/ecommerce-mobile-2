import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../repositories/authentication/authentication_repository.dart';
import '../../../features/shop/models/cart_item_model.dart';
import '../../../utils/http/dio_client.dart';

/// Sepet uçları (`Cart/...`).
///
/// 🔴 Sepet kullanıcıya özeldir; [TCacheInterceptor] izin listesinde yoktur ve
/// asla önbelleklenmez — bayat bir sepet yanlış tutar demektir.
class ApiCartRepository extends GetxController {
  static ApiCartRepository get instance => Get.find();

  /// Uygulama genelinde paylaşılan Dio (bkz. [THttpClient]).
  final Dio _dio = THttpClient.dio;

  Options get _authOptions {
    final token = AuthenticationRepository.instance.customAuthToken.value;
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  bool _isSuccess(Map<String, dynamic> data) =>
      data['success'] == true || data['Success'] == true;

  dynamic _getData(Map<String, dynamic> data) => data['data'] ?? data['Data'];

  /// Backend sepetini çekip CartItemModel listesi olarak döner.
  ///
  /// Dönen `null` ile boş liste FARKLI anlamlara gelir ve karıştırılmamalıdır:
  ///   * `null`  → istek başarısız (ağ/sunucu hatası). Sunucudaki sepetin ne
  ///               olduğu BİLİNMİYOR, local sepet korunmalı.
  ///   * `[]`    → sunucudaki sepet gerçekten boş (ör. sipariş webden
  ///               tamamlandı ve backend sepeti tüketti). Local sepet
  ///               temizlenmeli.
  Future<List<CartItemModel>?> fetchUserCart(String userId) async {
    try {
      final response = await _dio.get(
        'cart/user/$userId',
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      if (_isSuccess(data)) {
        return _parseCartItems(_getData(data));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sepete ürün ekler. Güncel CartItemModel listesini döner.
  Future<List<CartItemModel>> addToCart({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post(
        'cart/add',
        data: {
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        },
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      if (_isSuccess(data)) {
        return _parseCartItems(_getData(data));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Sepet öğesinin miktarını günceller. Güncel CartItemModel listesini döner.
  Future<List<CartItemModel>> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.put(
        'cart/update-quantity',
        data: {
          'cartItemId': cartItemId,
          'quantity': quantity,
        },
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      if (_isSuccess(data)) {
        return _parseCartItems(_getData(data));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Sepetten ürün siler. Güncel CartItemModel listesini döner.
  Future<List<CartItemModel>> removeItem(String cartItemId) async {
    try {
      final response = await _dio.delete(
        'cart/remove/$cartItemId',
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      if (_isSuccess(data)) {
        return _parseCartItems(_getData(data));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Sepeti tamamen temizler.
  Future<bool> clearCart(String userId) async {
    try {
      final response = await _dio.delete(
        'cart/clear/$userId',
        options: _authOptions,
      );
      final data = response.data as Map<String, dynamic>;
      return _isSuccess(data);
    } catch (_) {
      return false;
    }
  }

  /// Backend'den gelen cart data'sını CartItemModel listesine dönüştürür.
  List<CartItemModel> _parseCartItems(dynamic cartData) {
    if (cartData == null) return [];
    final rawItems = (cartData['items'] ?? cartData['Items']) as List<dynamic>? ?? [];
    return rawItems.map((item) {
      final pid = (item['productId'] ?? item['ProductId'])?.toString() ?? '';
      final cid = (item['cartItemId'] ?? item['CartItemId'])?.toString();
      final name = (item['productName'] ?? item['ProductName'])?.toString() ?? '';
      final image = (item['productImage'] ?? item['ProductImage'])?.toString();
      final unitPrice = _toDouble(item['unitPrice'] ?? item['UnitPrice']);
      final qty = (item['quantity'] ?? item['Quantity'] ?? 1) as int;

      return CartItemModel(
        productId: pid,
        cartItemId: cid,
        title: name,
        price: unitPrice,
        salePrice: 0.0,
        image: image,
        quantity: qty,
        erpSource: _erpSourceOf(item),
      );
    }).toList();
  }

  /// Sepet kaleminin şirket kodunu çözer.
  ///
  /// `CartItem` DTO'sunda ayrı bir `ErpSource` alanı **yok**; şirket
  /// `ProductSnapshot` JSON metninin içinde (`erpSource`) taşınıyor (backend
  /// M1'den beri yazıyor). Snapshot yok/bozuksa boş döner — kalem sepette
  /// "Diğer" başlığı altında görünür, siparişin bölünmesi bundan etkilenmez.
  /// Uca bir gün `ErpSource` eklenirse burada tek satır yeter.
  String _erpSourceOf(dynamic item) {
    final direct = item['erpSource'] ?? item['ErpSource'] ?? item['erpsource'];
    if (direct != null && direct.toString().isNotEmpty) return direct.toString();

    final raw = item['productSnapshot'] ?? item['ProductSnapshot'] ?? item['productsnapshot'];
    if (raw is! String || raw.isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final value = decoded['erpSource'] ?? decoded['ErpSource'];
        if (value != null) return value.toString();
      }
    } catch (_) {
      // Snapshot bozuk — şirket bilinmiyor, kalem yine de sepette kalır.
    }
    return '';
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
