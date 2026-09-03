/// Ana sayfa afişleri (`banners`).
library;

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/shop/models/banner_model.dart';
import 'banner_repository.dart';

class ApiBannerRepository extends TApiRepositoryController<BannerModel>
    implements BannerRepository {
  static ApiBannerRepository get instance => Get.find();

  ApiBannerRepository()
      : super(
          fromJson: (json) => BannerModel.fromJson(
            json['id']?.toString() ?? '',
            {
              'imageUrl':    json['imageUrl']    ?? json['ImageUrl']    ?? '',
              'title':       json['title']       ?? json['Title']       ?? '',
              'description': json['description'] ?? json['Description'] ?? '',
              'targetType':  json['targetType']  ?? json['TargetType']  ?? 'homeScreen',
              'targetId':    json['targetId']    ?? json['TargetId'],
              'targetTitle': json['targetTitle'] ?? json['TargetTitle'],
              'customUrl':   json['customUrl']   ?? json['CustomUrl'],
              'isActive':    json['isActive']    ?? json['IsActive']    ?? true,
              'isFeatured':  json['isFeatured']  ?? json['IsFeatured']  ?? false,
              'startDate':   json['startDate']   ?? json['StartDate'],
              'endDate':     json['endDate']     ?? json['EndDate'],
              'clicks':      json['clicks']      ?? json['Clicks']      ?? 0,
              'createdAt':   json['createdAt']   ?? json['CreatedAt'],
              'updateAt':    json['updatedAt']   ?? json['UpdatedAt'],
            },
          ),
          toJson: (item) => {
            'ImageUrl':    item.imageUrl,
            'Title':       item.title,
            'Description': item.description,
            'TargetType':  item.targetType.name,
            'TargetId':    item.targetId ?? '',
            'TargetTitle': item.targetTitle ?? '',
            'CustomUrl':   item.customUrl ?? '',
            'IsActive':    item.isActive,
            'IsFeatured':  item.isFeatured,
            'StartDate':   item.startDate?.toIso8601String(),
            'EndDate':     item.endDate?.toIso8601String(),
          },
          getId: (item) => item.id,
        );

  @override
  String getEndpoint() => 'banners';

  @override
  Future<List<BannerModel>> fetchAllItems() async {
    try {
      final response = await dio.get(
        getEndpoint(),
        queryParameters: {'isActive': true},
      );

      if (response.data['Success'] == true) {
        final List<dynamic> dataList = response.data['Data'] as List<dynamic>? ?? [];
        return dataList.map((json) => fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw response.data['Message'] ?? 'Failed to fetch banners';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<BannerModel> fetchSingleItem(String id) async {
    try {
      final response = await dio.get('${getEndpoint()}/$id');

      if (response.data['Success'] == true) {
        return fromJson(response.data['Data'] as Map<String, dynamic>);
      } else {
        throw response.data['Message'] ?? 'Failed to fetch banner';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<String> addItem(BannerModel item) async {
    try {
      final response = await dio.post(getEndpoint(), data: toJson(item));

      if (response.data['Success'] == true) {
        return response.data['Data']?['Id']?.toString() ?? '';
      } else {
        throw response.data['Message'] ?? 'Failed to add banner';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> updateItem(BannerModel item) async {
    try {
      final response = await dio.put('${getEndpoint()}/${item.id}', data: toJson(item));

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to update banner';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> updateSingleField(String id, Map<String, dynamic> json) async {
    try {
      final response = await dio.patch('${getEndpoint()}/$id', data: json);

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to update banner';
      }
    } catch (e) {
      throw handleException(e);
    }
  }

  @override
  Future<void> deleteItem(BannerModel item) async {
    try {
      final response = await dio.delete('${getEndpoint()}/${getId(item)}');

      if (response.data['Success'] != true) {
        throw response.data['Message'] ?? 'Failed to delete banner';
      }
    } catch (e) {
      throw handleException(e);
    }
  }
}
