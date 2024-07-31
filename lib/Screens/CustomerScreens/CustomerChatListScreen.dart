import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:badges/badges.dart' as badges;
import 'package:bb/ChatScreen.dart';

class CustomerChatListScreen extends StatefulWidget {
  final String customerId;

  CustomerChatListScreen({required this.customerId});

  @override
  _CustomerChatListScreenState createState() => _CustomerChatListScreenState();
}

class _CustomerChatListScreenState extends State<CustomerChatListScreen> {
  final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child('chats');
  final DatabaseReference _restaurantsRef = FirebaseDatabase.instance.ref().child('restaurant_users');
  Map<String, String> restaurantNames = {};
  Map<String, int> unreadCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantNames();
    _fetchUnreadCounts();
  }

  Future<void> _fetchRestaurantNames() async {
    DataSnapshot snapshot = await _restaurantsRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> restaurantData = snapshot.value as Map<dynamic, dynamic>;
      Map<String, String> tempRestaurantNames = {};
      restaurantData.forEach((key, value) {
        tempRestaurantNames[key] = value['restaurant_name'];
      });
      setState(() {
        restaurantNames = tempRestaurantNames;
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
          if (customerId == widget.customerId) {
            int unreadCount = 0;
            Map<dynamic, dynamic> messages = value as Map<dynamic, dynamic>;
            messages.forEach((messageKey, messageValue) {
              if (messageValue['senderId'] == restaurantId && !messageValue['read']) {
                unreadCount++;
              }
            });
            if (unreadCount > 0) {
              tempUnreadCounts[restaurantId] = unreadCount;
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
          List<String> restaurantIds = chatData.keys
              .where((key) => key.toString().contains(widget.customerId))
              .map((key) => key.toString().split('~')[1])
              .toList();

          restaurantIds = restaurantIds.toSet().toList(); // Remove duplicates

          return ListView.builder(
            itemCount: restaurantIds.length,
            itemBuilder: (context, index) {
              String restaurantId = restaurantIds[index];
              String restaurantName = restaurantNames[restaurantId] ?? 'Unknown Restaurant';
              int unreadCount = unreadCounts[restaurantId] ?? 0;

              return Slidable(
                key: Key(restaurantId),
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
                    child: Text(restaurantName[0]),
                  ),
                  title: Text(restaurantName),
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
                          customerId: widget.customerId,
                          restaurantId: restaurantId,
                          isCustomer: true,
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
