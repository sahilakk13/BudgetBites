class Review {
  final String reviewId;
  final String customerId;
  final String customerName;
  final String restaurantId;
  final String restaurantName;
  final double rating;
  final String comment;
  final String? imageUrl;
  final List<Reply> replies;
  final int timestamp;

  Review({
    required this.reviewId,
    required this.customerId,
    required this.customerName,
    required this.restaurantId,
    required this.restaurantName,
    required this.rating,
    required this.comment,
    this.imageUrl,
    this.replies = const [],
    required this.timestamp,
  });

  factory Review.fromMap(String reviewId, Map<String, dynamic> map) {
    return Review(
      reviewId: reviewId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      restaurantId: map['restaurantId'] ?? '',
      restaurantName: map['restaurantName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      imageUrl: map['imageUrl'],
      replies: (map['replies'] as Map<dynamic, dynamic>?)
          ?.values
          .map((value) => Reply.fromMap(Map<String, dynamic>.from(value)))
          .toList() ??
          [],
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewId': reviewId,
      'customerId': customerId,
      'customerName': customerName,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'rating': rating,
      'comment': comment,
      'imageUrl': imageUrl,
      'replies': replies.map((reply) => reply.toMap()).toList(),
      'timestamp': timestamp,
    };
  }
}


class Reply {
  final String replyId;
  final String userId;
  final String userName;
  final String message;
  final String? imageUrl;
  final int timestamp;

  Reply({
    required this.replyId,
    required this.userId,
    required this.userName,
    required this.message,
    this.imageUrl,
    required this.timestamp,
  });

  factory Reply.fromMap(Map<String, dynamic> map) {
    return Reply(
      replyId: map['replyId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      message: map['message'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'replyId': replyId,
      'userId': userId,
      'userName': userName,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }
}














// class Review {
//   final String reviewId;
//   final String customerId;
//   final String customerName;
//   final String restaurantId;
//   final String restaurantName;
//   final double rating;
//   final String comment;
//   final String? imageUrl;
//   final List<Reply> replies;
//
//   Review({
//     required this.reviewId,
//     required this.customerId,
//     required this.customerName,
//     required this.restaurantId,
//     required this.restaurantName,
//     required this.rating,
//     required this.comment,
//     this.imageUrl,
//     this.replies = const [],
//   });
//
//   factory Review.fromMap(String reviewId, Map<String, dynamic> map) {
//     return Review(
//       reviewId: reviewId,
//       customerId: map['customerId'],
//       customerName: map['customerName'],
//       restaurantId: map['restaurantId'],
//       restaurantName: map['restaurantName'],
//       rating: map['rating'].toDouble(),
//       comment: map['comment'],
//       imageUrl: map['imageUrl'],
//       replies: (map['replies'] as Map<dynamic, dynamic>?)
//           ?.values
//           .map((value) => Reply.fromMap(Map<String, dynamic>.from(value)))
//           .toList() ??
//           [],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'reviewId': reviewId,
//       'customerId': customerId,
//       'customerName': customerName,
//       'restaurantId': restaurantId,
//       'restaurantName': restaurantName,
//       'rating': rating,
//       'comment': comment,
//       'imageUrl': imageUrl,
//       'replies': replies.map((reply) => reply.toMap()).toList(),
//     };
//   }
// }
//
//
// class Reply {
//   final String replyId;
//   final String userId;
//   final String userName;
//   final String message;
//   final String? imageUrl;
//
//   Reply({
//     required this.replyId,
//     required this.userId,
//     required this.userName,
//     required this.message,
//     this.imageUrl,
//   });
//
//   factory Reply.fromMap(Map<String, dynamic> map) {
//     return Reply(
//       replyId: map['replyId'],
//       userId: map['userId'],
//       userName: map['userName'],
//       message: map['message'],
//       imageUrl: map['imageUrl'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'replyId': replyId,
//       'userId': userId,
//       'userName': userName,
//       'message': message,
//       'imageUrl': imageUrl,
//     };
//   }
// }









// class Review {
//   final String customerId;
//   final String customerName;
//   final String restaurantId;
//   final String restaurantName;
//   final double rating;
//   final String comment;
//   final String? imageUrl;
//
//   Review({
//     required this.customerId,
//     required this.customerName,
//     required this.restaurantId,
//     required this.restaurantName,
//     required this.rating,
//     required this.comment,
//     this.imageUrl,
//   });
//
//   factory Review.fromMap(Map<String, dynamic> map) {
//     return Review(
//       customerId: map['customerId'],
//       customerName: map['customerName'],
//       restaurantId: map['restaurantId'],
//       restaurantName: map['restaurantName'],
//       rating: map['rating'].toDouble(),
//       comment: map['comment'],
//       imageUrl: map['imageUrl'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'customerId': customerId,
//       'customerName': customerName,
//       'restaurantId': restaurantId,
//       'restaurantName': restaurantName,
//       'rating': rating,
//       'comment': comment,
//       'imageUrl': imageUrl,
//     };
//   }
// }
