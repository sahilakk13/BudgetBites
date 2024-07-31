import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:badges/badges.dart' as badges;
import 'package:bb/ChatScreen.dart';

class RestaurantChatListScreen extends StatefulWidget {
  final String restaurantId;

  RestaurantChatListScreen({required this.restaurantId});

  @override
  _RestaurantChatListScreenState createState() => _RestaurantChatListScreenState();
}

class _RestaurantChatListScreenState extends State<RestaurantChatListScreen> {
  final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
  final DatabaseReference _customersRef = FirebaseDatabase.instance.ref().child('customers');
  Map<String, String> customerNames = {};
  Map<String, int> unreadCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomerNames();
    _fetchUnreadCounts();
  }

  Future<void> _fetchCustomerNames() async {
    DataSnapshot snapshot = await _customersRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> customerData = snapshot.value as Map<dynamic, dynamic>;
      Map<String, String> tempCustomerNames = {};
      customerData.forEach((key, value) {
        tempCustomerNames[key] = value['username'];
      });
      setState(() {
        customerNames = tempCustomerNames;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUnreadCounts() async {
    _chatsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> chatData = event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, int> tempUnreadCounts = {};
        chatData.forEach((key, value) {
          String customerId = key.toString().split('~')[0];
          String restaurantId = key.toString().split('~')[1];
          if (restaurantId == widget.restaurantId) {
            int unreadCount = 0;
            Map<dynamic, dynamic> messages = value as Map<dynamic, dynamic>;
            messages.forEach((messageKey, messageValue) {
              if (messageValue['senderId'] == customerId && !messageValue['read']) {
                unreadCount++;
              }
            });
            if (unreadCount > 0) {
              tempUnreadCounts[customerId] = unreadCount;
            }
          }
        });
        setState(() {
          unreadCounts = tempUnreadCounts;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<DatabaseEvent>(
        stream: _chatsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats'));
          }
          if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
            return Center(child: Text('No chats available'));
          }

          Map<dynamic, dynamic> chatData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<String> customerIds = chatData.keys
              .where((key) => key.toString().contains(widget.restaurantId))
              .map((key) => key.toString().split('~')[0])
              .toList();

          customerIds = customerIds.toSet().toList(); // Remove duplicates

          return ListView.builder(
            itemCount: customerIds.length,
            itemBuilder: (context, index) {
              String customerId = customerIds[index];
              String customerName = customerNames[customerId] ?? 'Unknown Customer';
              int unreadCount = unreadCounts[customerId] ?? 0;

              return Slidable(
                key: Key(customerId),
                endActionPane: ActionPane(
                  motion: DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        // Add your delete action here
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Text(customerName[0]),
                  ),
                  title: Text(customerName),
                  trailing: unreadCount > 0
                      ? badges.Badge(
                    badgeContent: Text(
                      unreadCount.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: Colors.red,
                    ),
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          restaurantId: widget.restaurantId,
                          customerId: customerId,
                          isCustomer: false,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}







// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:bb/ChatScreen.dart';
//
// class RestaurantChatListScreen extends StatefulWidget {
//   final String restaurantId;
//
//   RestaurantChatListScreen({required this.restaurantId});
//
//   @override
//   _RestaurantChatListScreenState createState() => _RestaurantChatListScreenState();
// }
//
// class _RestaurantChatListScreenState extends State<RestaurantChatListScreen> {
//   final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
//   final DatabaseReference _customersRef = FirebaseDatabase.instance.ref().child('customers');
//   Map<String, String> customerNames = {};
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchCustomerNames();
//   }
//
//   Future<void> _fetchCustomerNames() async {
//     DataSnapshot snapshot = await _customersRef.get();
//     if (snapshot.exists) {
//       Map<dynamic, dynamic> customerData = snapshot.value as Map<dynamic, dynamic>;
//       Map<String, String> tempCustomerNames = {};
//       customerData.forEach((key, value) {
//         tempCustomerNames[key] = value['username'];
//       });
//       setState(() {
//         customerNames = tempCustomerNames;
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Chats'),
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
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : StreamBuilder<DatabaseEvent>(
//         stream: _chatsRef.onValue,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error loading chats'));
//           }
//           if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
//             return Center(child: Text('No chats available'));
//           }
//
//           Map<dynamic, dynamic> chatData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//           List<String> customerIds = chatData.keys
//               .where((key) => key.toString().contains(widget.restaurantId))
//               .map((key) => key.toString().split('~')[0])
//               .toList();
//
//           customerIds = customerIds.toSet().toList(); // Remove duplicates
//
//           return ListView.builder(
//             itemCount: customerIds.length,
//             itemBuilder: (context, index) {
//               String customerId = customerIds[index];
//               String customerName = customerNames[customerId] ?? 'Unknown Customer';
//
//               return ListTile(
//                 title: Text(customerName),
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => ChatScreen(
//                         customerId: customerId,
//                         restaurantId: widget.restaurantId,
//                         isCustomer: false, // Indicate that the restaurant is using this screen
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
