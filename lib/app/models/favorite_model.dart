import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;
  final String userId;
  final String favoriteUserId;
  final DateTime createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.favoriteUserId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'favoriteUserId': favoriteUserId,
      'createdAt': createdAt,
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map, String id) {
    return Favorite(
      id: id,
      userId: map['userId'],
      favoriteUserId: map['favoriteUserId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
