import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String customerId;
  final String restaurantId;
  final bool isCustomer;

  ChatScreen({required this.customerId, required this.restaurantId, required this.isCustomer});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _sendMessage({String? imageUrl}) {
    if (_controller.text.isNotEmpty || imageUrl != null) {
      final chatId = '${widget.customerId}~${widget.restaurantId}';
      final messageRef = _chatsRef.child(chatId).push();
      messageRef.set({
        'senderId': widget.isCustomer ? widget.customerId : widget.restaurantId,
        'message': _controller.text.isNotEmpty ? _controller.text : '',
        'imageUrl': imageUrl ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _controller.clear();
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final chatId = '${widget.customerId}~${widget.restaurantId}';
      final storageRef = FirebaseStorage.instance.ref().child('chat_images').child('$chatId/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();
      _sendMessage(imageUrl: imageUrl);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatId = '${widget.customerId}~${widget.restaurantId}';
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
                  List<Map<dynamic, dynamic>> messages = [];
                  Map<dynamic, dynamic>? data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                  data?.forEach((key, value) {
                    messages.add({'key': key, ...value});
                  });
                  messages.sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

                  // Scroll to bottom when new data is received
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCustomerMessage = message['senderId'] == widget.customerId;
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: isCustomerMessage ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (message['imageUrl'] != null && message['imageUrl'].isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        content: Image.network(message['imageUrl']),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    message['imageUrl'],
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  color: isCustomerMessage ? Colors.blue[200] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (message['message'] != null && message['message'].isNotEmpty)
                                      Text(
                                        message['message'],
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    SizedBox(height: 5),
                                    Text(
                                      DateFormat('hh:mm a').format(
                                          DateTime.fromMillisecondsSinceEpoch(message['timestamp'] ?? 0)),
                                      style: TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return Center(child: Text('No messages'));
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.photo, color: Colors.amber[800]),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Send a message...',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.amber[800]),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'dart:io';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//   final bool isCustomer;
//
//   ChatScreen({required this.customerId, required this.restaurantId, required this.isCustomer});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//   final ImagePicker _picker = ImagePicker();
//
//   void _sendMessage({String? imageUrl}) {
//     if (_controller.text.isNotEmpty || imageUrl != null) {
//       final chatId = '${widget.customerId}~${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.isCustomer ? widget.customerId : widget.restaurantId,
//         'message': _controller.text.isNotEmpty ? _controller.text : '',
//         'imageUrl': imageUrl ?? '',
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       final file = File(pickedFile.path);
//       final chatId = '${widget.customerId}~${widget.restaurantId}';
//       final storageRef = FirebaseStorage.instance.ref().child('chat_images').child('$chatId/${DateTime.now().millisecondsSinceEpoch}');
//       await storageRef.putFile(file);
//       final imageUrl = await storageRef.getDownloadURL();
//       _sendMessage(imageUrl: imageUrl);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}~${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic>? data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
//                   data?.forEach((key, value) {
//                     messages.add({'key': key, ...value});
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isCustomerMessage = message['senderId'] == widget.customerId;
//                       return Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Align(
//                           alignment: isCustomerMessage ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: <Widget>[
//                               if (message['imageUrl'] != null && message['imageUrl'].isNotEmpty)
//                                 GestureDetector(
//                                   onTap: () {
//                                     showDialog(
//                                       context: context,
//                                       builder: (_) => AlertDialog(
//                                         content: Image.network(message['imageUrl']),
//                                       ),
//                                     );
//                                   },
//                                   child: Image.network(
//                                     message['imageUrl'],
//                                     height: 200,
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               Container(
//                                 decoration: BoxDecoration(
//                                   color: isCustomerMessage ? Colors.blue[200] : Colors.grey[300],
//                                   borderRadius: BorderRadius.circular(10.0),
//                                 ),
//                                 padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: <Widget>[
//                                     if (message['message'] != null && message['message'].isNotEmpty)
//                                       Text(
//                                         message['message'],
//                                         style: TextStyle(
//                                           fontSize: 16.0,
//                                           color: Colors.black87,
//                                         ),
//                                       ),
//                                     SizedBox(height: 5),
//                                     Text(
//                                       DateFormat('hh:mm a').format(
//                                           DateTime.fromMillisecondsSinceEpoch(message['timestamp'] ?? 0)),
//                                       style: TextStyle(fontSize: 12, color: Colors.black54),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 IconButton(
//                   icon: Icon(Icons.photo, color: Colors.amber[800]),
//                   onPressed: _pickImage,
//                 ),
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8.0),
//                 IconButton(
//                   icon: Icon(Icons.send, color: Colors.amber[800]),
//                   onPressed: () => _sendMessage(),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//   final bool isCustomer;  // Add this parameter to differentiate
//
//   ChatScreen({required this.customerId, required this.restaurantId, required this.isCustomer});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       final chatId = '${widget.customerId}~${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.isCustomer ? widget.customerId : widget.restaurantId,  // Set sender ID based on user type
//         'message': _controller.text,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}~${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   data.forEach((key, value) {
//                     messages.add(value);
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isCustomerMessage = message['senderId'] == widget.customerId;
//                       return Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Align(
//                           alignment: isCustomerMessage ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: isCustomerMessage ? Colors.blue[200] : Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(
//                                   message['message'],
//                                   style: TextStyle(
//                                     fontSize: 16.0,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 SizedBox(height: 5),
//                                 Text(
//                                   DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message['timestamp'])),
//                                   style: TextStyle(fontSize: 12, color: Colors.black54),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8.0),
//                 IconButton(
//                   icon: Icon(Icons.send, color: Colors.amber[800]),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//
//   ChatScreen({required this.customerId, required this.restaurantId});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       final chatId = '${widget.customerId}~${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.customerId,
//         'message': _controller.text,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}~${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   data.forEach((key, value) {
//                     messages.add(value);
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isMe = message['senderId'] == widget.customerId;
//                       return ListTile(
//                         title: Align(
//                           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               color: isMe ? Colors.blue[200] : Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(message['message']),
//                                 SizedBox(height: 5),
//                                 Text(
//                                   DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message['timestamp'])),
//                                   style: TextStyle(fontSize: 10, color: Colors.black54),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//
//   ChatScreen({required this.customerId, required this.restaurantId});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       final chatId = '${widget.customerId}_${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.customerId,
//         'message': _controller.text,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}_${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   data.forEach((key, value) {
//                     messages.add(value);
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isMe = message['senderId'] == widget.customerId;
//                       return ListTile(
//                         title: Align(
//                           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               color: isMe ? Colors.blue[200] : Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(message['message']),
//                                 SizedBox(height: 5),
//                                 Text(
//                                   DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message['timestamp'])),
//                                   style: TextStyle(fontSize: 10, color: Colors.black54),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//   final bool isCustomer;  // Add this parameter to differentiate
//
//   ChatScreen({required this.customerId, required this.restaurantId, required this.isCustomer});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       final chatId = '${widget.customerId}~${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.isCustomer ? widget.customerId : widget.restaurantId,  // Set sender ID based on user type
//         'message': _controller.text,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}~${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   data.forEach((key, value) {
//                     messages.add(value);
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isCustomerMessage = message['senderId'] == widget.customerId;
//                       return Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Align(
//                           alignment: isCustomerMessage ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: isCustomerMessage ? Colors.blue[200] : Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(
//                                   message['message'],
//                                   style: TextStyle(
//                                     fontSize: 16.0,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 SizedBox(height: 5),
//                                 Text(
//                                   DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message['timestamp'])),
//                                   style: TextStyle(fontSize: 12, color: Colors.black54),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                       filled: true,
//                       fillColor: Colors.grey[200],
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30.0),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8.0),
//                 IconButton(
//                   icon: Icon(Icons.send, color: Colors.amber[800]),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//
//   ChatScreen({required this.customerId, required this.restaurantId});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       final chatId = '${widget.customerId}~${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.customerId,
//         'message': _controller.text,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}~${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   data.forEach((key, value) {
//                     messages.add(value);
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isMe = message['senderId'] == widget.customerId;
//                       return ListTile(
//                         title: Align(
//                           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               color: isMe ? Colors.blue[200] : Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(message['message']),
//                                 SizedBox(height: 5),
//                                 Text(
//                                   DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message['timestamp'])),
//                                   style: TextStyle(fontSize: 10, color: Colors.black54),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String customerId;
//   final String restaurantId;
//
//   ChatScreen({required this.customerId, required this.restaurantId});
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final TextEditingController _controller = TextEditingController();
//
//   void _sendMessage() {
//     if (_controller.text.isNotEmpty) {
//       final chatId = '${widget.customerId}_${widget.restaurantId}';
//       final messageRef = _chatsRef.child(chatId).push();
//       messageRef.set({
//         'senderId': widget.customerId,
//         'message': _controller.text,
//         'timestamp': DateTime.now().millisecondsSinceEpoch,
//       });
//       _controller.clear();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final chatId = '${widget.customerId}_${widget.restaurantId}';
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chat'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             child: StreamBuilder<DatabaseEvent>(
//               stream: _chatsRef.child(chatId).orderByChild('timestamp').onValue,
//               builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//                 if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
//                   List<Map<dynamic, dynamic>> messages = [];
//                   Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                   data.forEach((key, value) {
//                     messages.add(value);
//                   });
//                   messages.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
//                   return ListView.builder(
//                     itemCount: messages.length,
//                     itemBuilder: (context, index) {
//                       final message = messages[index];
//                       final isMe = message['senderId'] == widget.customerId;
//                       return ListTile(
//                         title: Align(
//                           alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//                           child: Container(
//                             padding: EdgeInsets.all(10.0),
//                             decoration: BoxDecoration(
//                               color: isMe ? Colors.blue[200] : Colors.grey[300],
//                               borderRadius: BorderRadius.circular(10.0),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: <Widget>[
//                                 Text(message['message']),
//                                 SizedBox(height: 5),
//                                 Text(
//                                   DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(message['timestamp'])),
//                                   style: TextStyle(fontSize: 10, color: Colors.black54),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 } else {
//                   return Center(child: Text('No messages'));
//                 }
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'Send a message...',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
