/// Sohbet katılımcısı (kullanıcı kimliği, ad, rol).
class ParticipantModel {
  String userId;
  String name;
  String profileImageURL;

  ParticipantModel({
    required this.userId,
    required this.name,
    required this.profileImageURL,
  });

  Map<String, dynamic> toFirestore() {
    return {'userId': userId, 'name': name, 'profileImageURL': profileImageURL};
  }

  static ParticipantModel fromFirestore(Map<String, dynamic> data) {
    return ParticipantModel(
      userId: data['UserId'] ?? data['userId'] ?? '',
      name: data['Name'] ?? data['name'] ?? 'Unknown',
      profileImageURL:
          data['ProfileImageUrl'] ??
          data['ProfileImageURL'] ??
          data['profileImageURL'] ??
          '',
    );
  }

  static ParticipantModel fromJson(Map<String, dynamic> data) =>
      fromFirestore(data);

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'profileImageURL': profileImageURL,
  };
}
