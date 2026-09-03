/// Öznitelik uçları (`attributes`).
///
/// ⚠️ `fetchAllItems()` burada UYGULANMAZ; temel sınıftan gelen hâli
/// `UnimplementedError` fırlatır. Liste isteyen `fetchPaginatedItems()`
/// kullanmalı. (Referansta da böyle.)
library;

import 'package:tstore_ecommerce_app/data/abstract/api_base_repository.dart';
import 'package:get/get.dart';
import '../../../features/shop/models/attribute_model.dart';
import 'attributes_repository.dart';

class ApiAttributeRepository extends TApiRepositoryController<AttributeModel>
    implements AttributeRepository {
  static ApiAttributeRepository get instance => Get.find();

  ApiAttributeRepository()
      : super(
          fromJson: (json) => AttributeModel.fromJson(
            json['id']?.toString() ?? '',
            {
              'name': json['name'] ?? json['Name'] ?? '',
              'attributeValues': (json['attributeValues'] ?? json['AttributeValues'] ?? []) is List
                  ? List<String>.from(json['attributeValues'] ?? json['AttributeValues'] ?? [])
                  : [],
              'isActive': json['isActive'] ?? json['IsActive'] ?? true,
              'isSearchable': json['isSearchable'] ?? json['IsSearchable'] ?? true,
              'isFilterable': json['isFilterable'] ?? json['IsFilterable'] ?? true,
              'isColorAttribute': json['isColorAttribute'] ?? json['IsColorAttribute'] ?? false,
              'createdAt': json['createdAt'] ?? json['CreatedAt'],
              'updatedAt': json['updatedAt'] ?? json['UpdatedAt'],
            },
          ),
          toJson: (item) => {
            'Name': item.name,
            'AttributeValues': item.attributeValues,
            'IsActive': item.isActive,
            'IsSearchable': item.isSearchable,
            'IsFilterable': item.isFilterable,
            'IsColorAttribute': item.isColorAttribute,
          },
          getId: (item) => item.id,
        );

  @override
  String getEndpoint() => 'attributes';
}
