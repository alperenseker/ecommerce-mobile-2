/// Ürün özniteliği (ad + seçilebilir değerler).
class ProductAttributeModel {
  String id;
  String attributeId;
  String name;
  List<String> values;
  bool isColorAttribute;

  ProductAttributeModel({
    required this.id,
    required this.attributeId,
    required this.name,
    required this.values,
    required this.isColorAttribute,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'attributeId': attributeId,
    'name': name,
    'values': values,
    'isColorAttribute': isColorAttribute,
  };

  factory ProductAttributeModel.fromJson(Map<String, dynamic> json) => ProductAttributeModel(
    id: json.containsKey('id') ? json['id'] : '',
    attributeId: json.containsKey('attributeId') ? json['attributeId'] : '',
    name: json.containsKey('name') ? json['name'] : '',
    values: json.containsKey('values') ? List<String>.from(json['values']) : [],
    isColorAttribute: json.containsKey('isColorAttribute') ? json['isColorAttribute'] ?? false : false,
  );
}
