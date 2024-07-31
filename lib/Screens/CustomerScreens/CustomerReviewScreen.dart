import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../Models/Review.dart';


class CustomerReviewScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String customerId;
  final String customerName;

  CustomerReviewScreen({
    required this.restaurantId,
    required this.restaurantName,
    required this.customerId,
    required this.customerName,
  });

  @override
  _CustomerReviewScreenState createState() => _CustomerReviewScreenState();
}

class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
  final DatabaseReference _reviewsRef = FirebaseDatabase.instance.ref().child('reviews');
  final ImagePicker _picker = ImagePicker();
  bool isSubmitting = false;
  XFile? _selectedImage;

  Future<void> _submitReview(double rating, String comment, XFile? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      File file = File(imageFile.path);
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('review_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
          .putFile(file);
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    DatabaseReference newReviewRef = _reviewsRef.child(widget.restaurantId).push();
    Review review = Review(
      reviewId: newReviewRef.key!,
      customerId: widget.customerId,
      customerName: widget.customerName,
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      rating: rating,
      comment: comment,
      imageUrl: imageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await newReviewRef.set(review.toMap());
  }

  Future<void> _submitReply(String reviewId, String message, XFile? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      File file = File(imageFile.path);
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('reply_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
          .putFile(file);
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    DatabaseReference newReplyRef = _reviewsRef.child(widget.restaurantId).child(reviewId).child('replies').push();
    Reply reply = Reply(
      replyId: newReplyRef.key!,
      userId: widget.customerId,
      userName: widget.customerName,
      message: message,
      imageUrl: imageUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await newReplyRef.set(reply.toMap());
  }

  void _showReviewDialog() {
    double? _selectedRating;
    final _commentController = TextEditingController();
    XFile? _selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Submit Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<double>(
                    value: _selectedRating,
                    hint: Text('Rating (1-5)'),
                    onChanged: (value) {
                      setState(() {
                        _selectedRating = value;
                      });
                    },
                    items: List.generate(5, (index) => (index + 1).toDouble())
                        .map((rating) => DropdownMenuItem(
                      value: rating,
                      child: Text(rating.toString()),
                    ))
                        .toList(),
                  ),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Comment',
                    ),
                  ),
                  SizedBox(height: 10),
                  _selectedImage == null
                      ? ElevatedButton(
                    onPressed: () async {
                      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                    child: Text('Upload Image'),
                  )
                      : Image.file(
                    File(_selectedImage!.path),
                    height: 100,
                    width: 100,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                isSubmitting
                    ? CircularProgressIndicator()
                    : TextButton(
                  onPressed: () async {
                    if (_selectedRating != null && _commentController.text.isNotEmpty) {
                      setState(() {
                        isSubmitting = true;
                      });
                      await _submitReview(_selectedRating!, _commentController.text, _selectedImage);
                      setState(() {
                        isSubmitting = false;
                      });
                      Navigator.of(context).pop();
                    } else {
                      // Show error message or handle empty fields
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReplyDialog(String reviewId) {
    final _replyController = TextEditingController();
    XFile? _selectedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Submit Reply'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _replyController,
                    decoration: InputDecoration(
                      labelText: 'Reply',
                    ),
                  ),
                  SizedBox(height: 10),
                  _selectedImage == null
                      ? ElevatedButton(
                    onPressed: () async {
                      XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                      setState(() {
                        _selectedImage = image;
                      });
                    },
                    child: Text('Upload Image'),
                  )
                      : Image.file(
                    File(_selectedImage!.path),
                    height: 100,
                    width: 100,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                isSubmitting
                    ? CircularProgressIndicator()
                    : TextButton(
                  onPressed: () async {
                    if (_replyController.text.isNotEmpty) {
                      setState(() {
                        isSubmitting = true;
                      });
                      await _submitReply(reviewId, _replyController.text, _selectedImage);
                      setState(() {
                        isSubmitting = false;
                      });
                      Navigator.of(context).pop();
                    } else {
                      // Show error message or handle empty fields
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          child: PhotoViewGallery(
            pageOptions: [
              PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            ],
            backgroundDecoration: BoxDecoration(
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _reviewsRef.child(widget.restaurantId).orderByChild('timestamp').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.snapshot.exists) {
            List<Review> reviews = [];
            final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              Review review = Review.fromMap(key, Map<String, dynamic>.from(value));
              reviews.add(review);
            });
            reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            return ListView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                Review review = reviews[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xFFFF9A8B),
                          child: Text(
                            review.customerName[0],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('${review.customerName} - ${review.rating}/5'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(review.comment),
                            if (review.imageUrl != null)
                              GestureDetector(
                                onTap: () => _showImagePreview(review.imageUrl!),
                                child: CachedNetworkImage(
                                  imageUrl: review.imageUrl!,
                                  placeholder: (context, url) => CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                  height: 100,
                                  width: 100,
                                ),
                              ),
                            if (review.replies.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: review.replies.length,
                                itemBuilder: (context, replyIndex) {
                                  Reply reply = review.replies[replyIndex];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        reply.userName[0],
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(reply.userName),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reply.message),
                                        if (reply.imageUrl != null)
                                          GestureDetector(
                                            onTap: () => _showImagePreview(reply.imageUrl!),
                                            child: CachedNetworkImage(
                                              imageUrl: reply.imageUrl!,
                                              placeholder: (context, url) => CircularProgressIndicator(),
                                              errorWidget: (context, url, error) => Icon(Icons.error),
                                              height: 100,
                                              width: 100,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            TextButton(
                              onPressed: () {
                                _showReplyDialog(review.reviewId);
                              },
                              child: Text('Reply'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No Reviews Available'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showReviewDialog,
        child: Icon(Icons.add),
        backgroundColor: Color(0xFFFF9A8B),
      ),
    );
  }
}






// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // Add this line for image caching
// import '../../Models/Review.dart';
// //import '../../Models/Reply.dart';
//
// class CustomerReviewScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//   final String customerId;
//   final String customerName;
//
//   CustomerReviewScreen({
//     required this.restaurantId,
//     required this.restaurantName,
//     required this.customerId,
//     required this.customerName,
//   });
//
//   @override
//   _CustomerReviewScreenState createState() => _CustomerReviewScreenState();
// }
//
// class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
//   final DatabaseReference _reviewsRef = FirebaseDatabase.instance.ref().child('reviews');
//   final ImagePicker _picker = ImagePicker();
//   List<Review> reviews = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchReviews();
//   }
//
//   Future<void> _fetchReviews() async {
//     _reviewsRef.child(widget.restaurantId).onChildAdded.listen((event) {
//       if (event.snapshot.exists) {
//         String reviewId = event.snapshot.key!;
//         Map<dynamic, dynamic> reviewData = event.snapshot.value as Map<dynamic, dynamic>;
//         Review review = Review.fromMap(reviewId, Map<String, dynamic>.from(reviewData));
//         setState(() {
//           reviews.add(review);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }
//
//   Future<void> _submitReview(double rating, String comment, XFile? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       File file = File(imageFile.path);
//       TaskSnapshot snapshot = await FirebaseStorage.instance
//           .ref('review_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
//           .putFile(file);
//       imageUrl = await snapshot.ref.getDownloadURL();
//     }
//
//     DatabaseReference newReviewRef = _reviewsRef.child(widget.restaurantId).push();
//     Review review = Review(
//       reviewId: newReviewRef.key!,
//       customerId: widget.customerId,
//       customerName: widget.customerName,
//       restaurantId: widget.restaurantId,
//       restaurantName: widget.restaurantName,
//       rating: rating,
//       comment: comment,
//       imageUrl: imageUrl,
//     );
//
//     await newReviewRef.set(review.toMap());
//   }
//
//   Future<void> _submitReply(String reviewId, String message, XFile? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       File file = File(imageFile.path);
//       TaskSnapshot snapshot = await FirebaseStorage.instance
//           .ref('reply_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
//           .putFile(file);
//       imageUrl = await snapshot.ref.getDownloadURL();
//     }
//
//     DatabaseReference newReplyRef = _reviewsRef.child(widget.restaurantId).child(reviewId).child('replies').push();
//     Reply reply = Reply(
//       replyId: newReplyRef.key!,
//       userId: widget.customerId,
//       userName: widget.customerName,
//       message: message,
//       imageUrl: imageUrl,
//     );
//
//     await newReplyRef.set(reply.toMap());
//   }
//
//   void _showReviewDialog() {
//     double? _selectedRating;
//     final _commentController = TextEditingController();
//     XFile? _selectedImage;
//     bool isSubmitting = false;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: Text('Submit Review'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   DropdownButton<double>(
//                     value: _selectedRating,
//                     hint: Text('Rating (1-5)'),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedRating = value;
//                       });
//                     },
//                     items: List.generate(5, (index) => (index + 1).toDouble())
//                         .map((rating) => DropdownMenuItem(
//                       value: rating,
//                       child: Text(rating.toString()),
//                     ))
//                         .toList(),
//                   ),
//                   TextField(
//                     controller: _commentController,
//                     decoration: InputDecoration(
//                       labelText: 'Comment',
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   _selectedImage == null
//                       ? ElevatedButton(
//                     onPressed: () async {
//                       XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       setState(() {
//                         _selectedImage = image;
//                       });
//                     },
//                     child: Text('Upload Image'),
//                   )
//                       : Image.file(
//                     File(_selectedImage!.path),
//                     height: 100,
//                     width: 100,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Cancel'),
//                 ),
//                 isSubmitting
//                     ? CircularProgressIndicator()
//                     : TextButton(
//                   onPressed: () async {
//                     if (_selectedRating != null && _commentController.text.isNotEmpty) {
//                       setState(() {
//                         isSubmitting = true;
//                       });
//                       await _submitReview(_selectedRating!, _commentController.text, _selectedImage);
//                       setState(() {
//                         isSubmitting = false;
//                       });
//                       Navigator.of(context).pop();
//                     } else {
//                       // Show error message or handle empty fields
//                     }
//                   },
//                   child: Text('Submit'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _showReplyDialog(String reviewId) {
//     final _replyController = TextEditingController();
//     XFile? _selectedImage;
//     bool isSubmittingReply = false;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: Text('Submit Reply'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: _replyController,
//                     decoration: InputDecoration(
//                       labelText: 'Reply',
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   _selectedImage == null
//                       ? ElevatedButton(
//                     onPressed: () async {
//                       XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       setState(() {
//                         _selectedImage = image;
//                       });
//                     },
//                     child: Text('Upload Image'),
//                   )
//                       : Image.file(
//                     File(_selectedImage!.path),
//                     height: 100,
//                     width: 100,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Cancel'),
//                 ),
//                 isSubmittingReply
//                     ? CircularProgressIndicator()
//                     : TextButton(
//                   onPressed: () async {
//                     if (_replyController.text.isNotEmpty) {
//                       setState(() {
//                         isSubmittingReply = true;
//                       });
//                       await _submitReply(reviewId, _replyController.text, _selectedImage);
//                       setState(() {
//                         isSubmittingReply = false;
//                       });
//                       Navigator.of(context).pop();
//                     } else {
//                       // Show error message or handle empty fields
//                     }
//                   },
//                   child: Text('Submit'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : reviews.isEmpty
//           ? Center(child: Text('No Reviews Available'))
//           : ListView.builder(
//         itemCount: reviews.length,
//         itemBuilder: (context, index) {
//           Review review = reviews[index];
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//             elevation: 5,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Color(0xFFFF9A8B),
//                     child: Text(
//                       review.customerName[0],
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   title: Text('${review.customerName} - ${review.rating}/5'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(review.comment),
//                       if (review.imageUrl != null)
//                         CachedNetworkImage( // Use CachedNetworkImage for caching
//                           imageUrl: review.imageUrl!,
//                           placeholder: (context, url) => CircularProgressIndicator(),
//                           errorWidget: (context, url, error) => Icon(Icons.error),
//                           height: 100,
//                           width: 100,
//                         ),
//                       if (review.replies.isNotEmpty)
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: review.replies.length,
//                           itemBuilder: (context, replyIndex) {
//                             Reply reply = review.replies[replyIndex];
//                             return ListTile(
//                               leading: CircleAvatar(
//                                 backgroundColor: Colors.blue,
//                                 child: Text(
//                                   reply.userName[0],
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                               title: Text(reply.userName),
//                               subtitle: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(reply.message),
//                                   if (reply.imageUrl != null)
//                                     CachedNetworkImage( // Use CachedNetworkImage for caching
//                                       imageUrl: reply.imageUrl!,
//                                       placeholder: (context, url) => CircularProgressIndicator(),
//                                       errorWidget: (context, url, error) => Icon(Icons.error),
//                                       height: 100,
//                                       width: 100,
//                                     ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       TextButton(
//                         onPressed: () {
//                           _showReplyDialog(review.reviewId);
//                         },
//                         child: Text('Reply'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showReviewDialog,
//         child: Icon(Icons.add),
//         backgroundColor: Color(0xFFFF9A8B),
//       ),
//     );
//   }
// }
//
//
//
//




// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import '../../Models/Review.dart';
// //import '../../Models/Reply.dart';
//
// class CustomerReviewScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//   final String customerId;
//   final String customerName;
//
//   CustomerReviewScreen({
//     required this.restaurantId,
//     required this.restaurantName,
//     required this.customerId,
//     required this.customerName,
//   });
//
//   @override
//   _CustomerReviewScreenState createState() => _CustomerReviewScreenState();
// }
//
// class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
//   final DatabaseReference _reviewsRef = FirebaseDatabase.instance.ref().child('reviews');
//   final ImagePicker _picker = ImagePicker();
//   List<Review> reviews = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchReviews();
//   }
//
//   Future<void> _fetchReviews() async {
//     _reviewsRef.child(widget.restaurantId).onChildAdded.listen((event) {
//       if (event.snapshot.exists) {
//         String reviewId = event.snapshot.key!;
//         Map<dynamic, dynamic> reviewData = event.snapshot.value as Map<dynamic, dynamic>;
//         Review review = Review.fromMap(reviewId, Map<String, dynamic>.from(reviewData));
//         setState(() {
//           reviews.add(review);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }
//
//   Future<void> _submitReview(double rating, String comment, XFile? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       File file = File(imageFile.path);
//       TaskSnapshot snapshot = await FirebaseStorage.instance
//           .ref('review_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
//           .putFile(file);
//       imageUrl = await snapshot.ref.getDownloadURL();
//     }
//
//     DatabaseReference newReviewRef = _reviewsRef.child(widget.restaurantId).push();
//     Review review = Review(
//       reviewId: newReviewRef.key!,
//       customerId: widget.customerId,
//       customerName: widget.customerName,
//       restaurantId: widget.restaurantId,
//       restaurantName: widget.restaurantName,
//       rating: rating,
//       comment: comment,
//       imageUrl: imageUrl,
//     );
//
//     await newReviewRef.set(review.toMap());
//   }
//
//   Future<void> _submitReply(String reviewId, String message, XFile? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       File file = File(imageFile.path);
//       TaskSnapshot snapshot = await FirebaseStorage.instance
//           .ref('reply_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
//           .putFile(file);
//       imageUrl = await snapshot.ref.getDownloadURL();
//     }
//
//     DatabaseReference newReplyRef = _reviewsRef.child(widget.restaurantId).child(reviewId).child('replies').push();
//     Reply reply = Reply(
//       replyId: newReplyRef.key!,
//       userId: widget.customerId,
//       userName: widget.customerName,
//       message: message,
//       imageUrl: imageUrl,
//     );
//
//     await newReplyRef.set(reply.toMap());
//   }
//
//   void _showReviewDialog() {
//     double? _selectedRating;
//     final _commentController = TextEditingController();
//     XFile? _selectedImage;
//     bool isSubmitting = false;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: Text('Submit Review'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   DropdownButton<double>(
//                     value: _selectedRating,
//                     hint: Text('Rating (1-5)'),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedRating = value;
//                       });
//                     },
//                     items: List.generate(5, (index) => (index + 1).toDouble())
//                         .map((rating) => DropdownMenuItem(
//                       value: rating,
//                       child: Text(rating.toString()),
//                     ))
//                         .toList(),
//                   ),
//                   TextField(
//                     controller: _commentController,
//                     decoration: InputDecoration(
//                       labelText: 'Comment',
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   _selectedImage == null
//                       ? ElevatedButton(
//                     onPressed: () async {
//                       XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       setState(() {
//                         _selectedImage = image;
//                       });
//                     },
//                     child: Text('Upload Image'),
//                   )
//                       : Image.file(
//                     File(_selectedImage!.path),
//                     height: 100,
//                     width: 100,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Cancel'),
//                 ),
//                 isSubmitting
//                     ? CircularProgressIndicator()
//                     : TextButton(
//                   onPressed: () async {
//                     if (_selectedRating != null && _commentController.text.isNotEmpty) {
//                       setState(() {
//                         isSubmitting = true;
//                       });
//                       await _submitReview(_selectedRating!, _commentController.text, _selectedImage);
//                       setState(() {
//                         isSubmitting = false;
//                       });
//                       Navigator.of(context).pop();
//                     } else {
//                       // Show error message or handle empty fields
//                     }
//                   },
//                   child: Text('Submit'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _showReplyDialog(String reviewId) {
//     final _replyController = TextEditingController();
//     XFile? _selectedImage;
//     bool isSubmittingReply = false;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: Text('Submit Reply'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: _replyController,
//                     decoration: InputDecoration(
//                       labelText: 'Reply',
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   _selectedImage == null
//                       ? ElevatedButton(
//                     onPressed: () async {
//                       XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       setState(() {
//                         _selectedImage = image;
//                       });
//                     },
//                     child: Text('Upload Image'),
//                   )
//                       : Image.file(
//                     File(_selectedImage!.path),
//                     height: 100,
//                     width: 100,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Cancel'),
//                 ),
//                 isSubmittingReply
//                     ? CircularProgressIndicator()
//                     : TextButton(
//                   onPressed: () async {
//                     if (_replyController.text.isNotEmpty) {
//                       setState(() {
//                         isSubmittingReply = true;
//                       });
//                       await _submitReply(reviewId, _replyController.text, _selectedImage);
//                       setState(() {
//                         isSubmittingReply = false;
//                       });
//                       Navigator.of(context).pop();
//                     } else {
//                       // Show error message or handle empty fields
//                     }
//                   },
//                   child: Text('Submit'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : reviews.isEmpty
//           ? Center(child: Text('No Reviews Available'))
//           : ListView.builder(
//         itemCount: reviews.length,
//         itemBuilder: (context, index) {
//           Review review = reviews[index];
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//             elevation: 5,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: Column(
//               children: [
//                 ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Color(0xFFFF9A8B),
//                     child: Text(
//                       review.customerName[0],
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                   title: Text('${review.customerName} - ${review.rating}/5'),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(review.comment),
//                       if (review.imageUrl != null) Image.network(review.imageUrl!),
//                       if (review.replies.isNotEmpty)
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: NeverScrollableScrollPhysics(),
//                           itemCount: review.replies.length,
//                           itemBuilder: (context, replyIndex) {
//                             Reply reply = review.replies[replyIndex];
//                             return ListTile(
//                               leading: CircleAvatar(
//                                 backgroundColor: Colors.blue,
//                                 child: Text(
//                                   reply.userName[0],
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               ),
//                               title: Text(reply.userName),
//                               subtitle: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(reply.message),
//                                   if (reply.imageUrl != null) Image.network(reply.imageUrl!),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       TextButton(
//                         onPressed: () {
//                           _showReplyDialog(review.reviewId);
//                         },
//                         child: Text('Reply'),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showReviewDialog,
//         child: Icon(Icons.add),
//         backgroundColor: Color(0xFFFF9A8B),
//       ),
//     );
//   }
// }
//







// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import '../../Models/Review.dart';
//
// class CustomerReviewScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//   final String customerId;
//   final String customerName;
//
//   CustomerReviewScreen({
//     required this.restaurantId,
//     required this.restaurantName,
//     required this.customerId,
//     required this.customerName,
//   });
//
//   @override
//   _CustomerReviewScreenState createState() => _CustomerReviewScreenState();
// }
//
// class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
//   final DatabaseReference _reviewsRef = FirebaseDatabase.instance.ref().child('reviews');
//   final ImagePicker _picker = ImagePicker();
//   List<Review> reviews = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchReviews();
//   }
//
//   Future<void> _fetchReviews() async {
//     _reviewsRef.child(widget.restaurantId).onChildAdded.listen((event) {
//       if (event.snapshot.exists) {
//         Map<dynamic, dynamic> reviewData = event.snapshot.value as Map<dynamic, dynamic>;
//         Review review = Review.fromMap(Map<String, dynamic>.from(reviewData));
//         setState(() {
//           reviews.add(review);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }
//
//   Future<void> _submitReview(double rating, String comment, XFile? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       File file = File(imageFile.path);
//       TaskSnapshot snapshot = await FirebaseStorage.instance
//           .ref('review_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
//           .putFile(file);
//       imageUrl = await snapshot.ref.getDownloadURL();
//     }
//
//     Review review = Review(
//       customerId: widget.customerId,
//       customerName: widget.customerName,
//       restaurantId: widget.restaurantId,
//       restaurantName: widget.restaurantName,
//       rating: rating,
//       comment: comment,
//       imageUrl: imageUrl,
//     );
//
//     await _reviewsRef.child(widget.restaurantId).push().set(review.toMap());
//   }
//
//   void _showReviewDialog() {
//     double? _selectedRating;
//     final _commentController = TextEditingController();
//     XFile? _selectedImage;
//     bool isSubmitting = false;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return AlertDialog(
//               title: Text('Submit Review'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   DropdownButton<double>(
//                     value: _selectedRating,
//                     hint: Text('Rating (1-5)'),
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedRating = value;
//                       });
//                     },
//                     items: List.generate(5, (index) => (index + 1).toDouble())
//                         .map((rating) => DropdownMenuItem(
//                       value: rating,
//                       child: Text(rating.toString()),
//                     ))
//                         .toList(),
//                   ),
//                   TextField(
//                     controller: _commentController,
//                     decoration: InputDecoration(
//                       labelText: 'Comment',
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   _selectedImage == null
//                       ? ElevatedButton(
//                     onPressed: () async {
//                       XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                       setState(() {
//                         _selectedImage = image;
//                       });
//                     },
//                     child: Text('Upload Image'),
//                   )
//                       : Image.file(
//                     File(_selectedImage!.path),
//                     height: 100,
//                     width: 100,
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('Cancel'),
//                 ),
//                 isSubmitting
//                     ? CircularProgressIndicator()
//                     : TextButton(
//                   onPressed: () async {
//                     if (_selectedRating != null && _commentController.text.isNotEmpty) {
//                       setState(() {
//                         isSubmitting = true;
//                       });
//                       await _submitReview(_selectedRating!, _commentController.text, _selectedImage);
//                       setState(() {
//                         isSubmitting = false;
//                       });
//                       Navigator.of(context).pop();
//                     } else {
//                       // Show error message or handle empty fields
//                     }
//                   },
//                   child: Text('Submit'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : reviews.isEmpty
//           ? Center(child: Text('No Reviews Available'))
//           : ListView.builder(
//         itemCount: reviews.length,
//         itemBuilder: (context, index) {
//           Review review = reviews[index];
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//             elevation: 5,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Color(0xFFFF9A8B),
//                 child: Text(
//                   review.customerName[0],
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text('${review.customerName} - ${review.rating}/5'),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(review.comment),
//                   if (review.imageUrl != null)
//                     Image.network(review.imageUrl!)
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showReviewDialog,
//         child: Icon(Icons.add),
//         backgroundColor: Color(0xFFFF9A8B),
//       ),
//     );
//   }
// }
//





// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import '../../Models/Review.dart';
//
// class CustomerReviewScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//   final String customerId;
//   final String customerName;
//
//   CustomerReviewScreen({
//     required this.restaurantId,
//     required this.restaurantName,
//     required this.customerId,
//     required this.customerName,
//   });
//
//   @override
//   _CustomerReviewScreenState createState() => _CustomerReviewScreenState();
// }
//
// class _CustomerReviewScreenState extends State<CustomerReviewScreen> {
//   final DatabaseReference _reviewsRef = FirebaseDatabase.instance.ref().child('reviews');
//   final ImagePicker _picker = ImagePicker();
//   List<Review> reviews = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchReviews();
//   }
//
//   Future<void> _fetchReviews() async {
//     _reviewsRef.child(widget.restaurantId).onValue.listen((event) {
//       if (event.snapshot.exists) {
//         Map<dynamic, dynamic> reviewData = event.snapshot.value as Map<dynamic, dynamic>;
//         List<Review> tempReviews = [];
//         reviewData.forEach((key, value) {
//           Review review = Review.fromMap(value);
//           tempReviews.add(review);
//         });
//         setState(() {
//           reviews = tempReviews;
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//       }
//     });
//   }
//
//   Future<void> _submitReview(double rating, String comment, XFile? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       File file = File(imageFile.path);
//       TaskSnapshot snapshot = await FirebaseStorage.instance
//           .ref('review_images/${widget.customerId}/${DateTime.now().millisecondsSinceEpoch}')
//           .putFile(file);
//       imageUrl = await snapshot.ref.getDownloadURL();
//     }
//
//     Review review = Review(
//       customerId: widget.customerId,
//       customerName: widget.customerName,
//       restaurantId: widget.restaurantId,
//       restaurantName: widget.restaurantName,
//       rating: rating,
//       comment: comment,
//       imageUrl: imageUrl,
//     );
//
//     await _reviewsRef.child(widget.restaurantId).push().set(review.toMap());
//   }
//
//   void _showReviewDialog() {
//     final _ratingController = TextEditingController();
//     final _commentController = TextEditingController();
//     XFile? _selectedImage;
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Submit Review'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: _ratingController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Rating (1-5)',
//                 ),
//               ),
//               TextField(
//                 controller: _commentController,
//                 decoration: InputDecoration(
//                   labelText: 'Comment',
//                 ),
//               ),
//               SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: () async {
//                   XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//                   setState(() {
//                     _selectedImage = image;
//                   });
//                 },
//                 child: Text('Upload Image'),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 double rating = double.parse(_ratingController.text);
//                 String comment = _commentController.text;
//
//                 await _submitReview(rating, comment, _selectedImage);
//                 Navigator.of(context).pop();
//               },
//               child: Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//         itemCount: reviews.length,
//         itemBuilder: (context, index) {
//           Review review = reviews[index];
//           return Card(
//             margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//             elevation: 5,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(15),
//             ),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Color(0xFFFF9A8B),
//                 child: Text(
//                   review.customerName[0],
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text('${review.customerName} - ${review.rating}/5'),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(review.comment),
//                   if (review.imageUrl != null)
//                     Image.network(review.imageUrl!)
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showReviewDialog,
//         child: Icon(Icons.add),
//         backgroundColor: Color(0xFFFF9A8B),
//       ),
//     );
//   }
// }
