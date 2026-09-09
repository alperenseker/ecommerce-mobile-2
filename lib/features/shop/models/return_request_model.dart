import '../../../utils/constants/enums.dart';
import 'cart_item_model.dart';

/// İade talebi modeli.
///
/// ⚠️ İade uçları sunucuda henüz yok (canlıda 404); model hazır duruyor.
class ReturnRequest {
  String id;
  String orderId;
  String userId;
  String userName;
  String userEmail;
  String userPhone;
  DateTime requestDate;
  ReturnType returnType;
  ReturnStatus status;
  ReturnReason reason;
  String description;
  List<String> photoUrls;
  List<CartItemModel> returnItems;

  // Admin/Vendor responses
  String? adminNote;
  String? vendorNote;
  String? approvedByAdminId;
  String? approvedByVendorId;
  DateTime? approvedAt;
  DateTime? rejectedAt;
  DateTime? updatedAt;

  // Refund details
  double? refundAmount;
  String? refundMethod;
  DateTime? refundProcessedAt;

  // Exchange details
  String? exchangeProductId;
  String? exchangeProductName;
  String? exchangeProductSize;
  String? exchangeProductColor;

  // Tracking
  String? returnTrackingNumber;
  String? returnCarrier;
  String? exchangeTrackingNumber;
  String? exchangeCarrier;

  ReturnRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.requestDate,
    required this.returnType,
    required this.status,
    required this.reason,
    required this.description,
    required this.photoUrls,
    required this.returnItems,
    this.adminNote,
    this.vendorNote,
    this.approvedByAdminId,
    this.approvedByVendorId,
    this.approvedAt,
    this.rejectedAt,
    this.updatedAt,
    this.refundAmount,
    this.refundMethod,
    this.refundProcessedAt,
    this.exchangeProductId,
    this.exchangeProductName,
    this.exchangeProductSize,
    this.exchangeProductColor,
    this.returnTrackingNumber,
    this.returnCarrier,
    this.exchangeTrackingNumber,
    this.exchangeCarrier,
  });

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'requestDate': requestDate,
      'returnType': returnType.name,
      'status': status.name,
      'reason': reason.name,
      'description': description,
      'photoUrls': photoUrls,
      'returnItems': returnItems.map((item) => item.toJson()).toList(),
      'adminNote': adminNote,
      'vendorNote': vendorNote,
      'approvedByAdminId': approvedByAdminId,
      'approvedByVendorId': approvedByVendorId,
      'approvedAt': approvedAt,
      'rejectedAt': rejectedAt,
      'updatedAt': updatedAt,
      'refundAmount': refundAmount,
      'refundMethod': refundMethod,
      'refundProcessedAt': refundProcessedAt,
      'exchangeProductId': exchangeProductId,
      'exchangeProductName': exchangeProductName,
      'exchangeProductSize': exchangeProductSize,
      'exchangeProductColor': exchangeProductColor,
      'returnTrackingNumber': returnTrackingNumber,
      'returnCarrier': returnCarrier,
      'exchangeTrackingNumber': exchangeTrackingNumber,
      'exchangeCarrier': exchangeCarrier,
    };
  }

  factory ReturnRequest.fromJson(String id, Map<String, dynamic> data) {
    return ReturnRequest(
      id: id,
      orderId: data['orderId'],
      userId: data['userId'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      userPhone: data['userPhone'],
      requestDate: DateTime.tryParse(data['requestDate'].toString()) ?? DateTime.now(),
      returnType: ReturnType.values.firstWhere((e) => e.name == data['returnType']),
      status: ReturnStatus.values.firstWhere((e) => e.name == data['status']),
      reason: ReturnReason.values.firstWhere((e) => e.name == data['reason']),
      description: data['description'],
      photoUrls: List<String>.from(data['photoUrls']),
      returnItems: (data['returnItems'] as List).map((item) => CartItemModel.fromJson(item)).toList(),
      adminNote: data['adminNote'],
      vendorNote: data['vendorNote'],
      approvedByAdminId: data['approvedByAdminId'],
      approvedByVendorId: data['approvedByVendorId'],
      approvedAt: data['approvedAt'] != null ? DateTime.tryParse(data['approvedAt'].toString()) : null,
      rejectedAt: data['rejectedAt'] != null ? DateTime.tryParse(data['rejectedAt'].toString()) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null,
      refundAmount: data['refundAmount']?.toDouble(),
      refundMethod: data['refundMethod'],
      refundProcessedAt: data['refundProcessedAt'] != null ? DateTime.tryParse(data['refundProcessedAt'].toString()) : null,
      exchangeProductId: data['exchangeProductId'],
      exchangeProductName: data['exchangeProductName'],
      exchangeProductSize: data['exchangeProductSize'],
      exchangeProductColor: data['exchangeProductColor'],
      returnTrackingNumber: data['returnTrackingNumber'],
      returnCarrier: data['returnCarrier'],
      exchangeTrackingNumber: data['exchangeTrackingNumber'],
      exchangeCarrier: data['exchangeCarrier'],
    );
  }

  static ReturnRequest empty() => ReturnRequest(
    id: '',
    orderId: '',
    userId: '',
    userName: '',
    userEmail: '',
    userPhone: '',
    requestDate: DateTime.now(),
    returnType: ReturnType.returnForRefund,
    status: ReturnStatus.requested,
    reason: ReturnReason.other,
    description: '',
    photoUrls: [],
    returnItems: [],
  );
}