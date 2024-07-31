import 'package:bb/Screens/CustomerScreens/CustomerReviewScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../Models/MenuItem.dart';
import '../../Models/Restaurant.dart';
import 'package:bb/ChatScreen.dart';// Import the ChatScreen

class MenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String customerId; // Add customerId
  final String customerName;

  MenuScreen({required this.restaurantId, required this.restaurantName, required this.customerId,required this.customerName});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _screens = <Widget>[
      MenuTab(restaurantId: widget.restaurantId),
      CustomerReviewScreen(restaurantId: widget.restaurantId, restaurantName: widget.restaurantName, customerId: widget.customerId, customerName: widget.customerName),
      ChatScreen(restaurantId: widget.restaurantId, customerId: widget.customerId,isCustomer: true,), // Add ChatTab
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFFF9A8B),
        onTap: _onItemTapped,
      ),
    );
  }
}

class MenuTab extends StatefulWidget {
  final String restaurantId;

  MenuTab({required this.restaurantId});

  @override
  _MenuTabState createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String _sortOrder = 'asc'; // Default sorting order

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort by:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sortOrder == 'asc' ? Color(0xFFFF9A8B) : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _sortOrder = 'asc';
                      });
                    },
                    child: Text(
                      'Price: Low to High',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sortOrder == 'desc' ? Color(0xFFFF9A8B) : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _sortOrder = 'desc';
                      });
                    },
                    child: Text(
                      'Price: High to Low',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}').onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error loading menu'));
              }
              if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
                return Center(child: Text('No menu available'));
              }

              Map<dynamic, dynamic> menuData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
              List<MenuItem> menuItems = menuData.entries.map((e) {
                final item = Map<String, dynamic>.from(e.value);
                return MenuItem.fromMap(e.key, item);
              }).toList();
              menuItems = menuItems.where((item) => item.available).toList(); // Filter out unavailable items
              menuItems = sortMenuItems(menuItems); // Sort the menu items

              return ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  MenuItem menuItem = menuItems[index];
                  print('Image URL: ${menuItem.imageUrl}'); // Debugging: Log the image URL

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFFFF9A8B),
                        backgroundImage: menuItem.imageUrl.isNotEmpty
                            ? NetworkImage(menuItem.imageUrl)
                            : null,
                        child: menuItem.imageUrl.isEmpty
                            ? Text(
                          menuItem.name[0],
                          style: TextStyle(color: Colors.white),
                        )
                            : null,
                      ),
                      title: Text(menuItem.name),
                      subtitle: Text(menuItem.description),
                      trailing: Text('PKR ${menuItem.price.toStringAsFixed(2)}'), // Ensure price is formatted correctly
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<MenuItem> sortMenuItems(List<MenuItem> menuItems) {
    if (_sortOrder == 'asc') {
      menuItems.sort((a, b) => a.price.compareTo(b.price));
    } else {
      menuItems.sort((a, b) => b.price.compareTo(a.price));
    }
    return menuItems;
  }
}

class ReviewTab extends StatelessWidget {
  final String restaurantId;

  ReviewTab({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder. Replace with actual review fetching and display logic.
    return Center(
      child: Text(
        'Reviews for $restaurantId',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ChatTab extends StatelessWidget {
  final String restaurantId;
  final String customerId;

  ChatTab({required this.restaurantId, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                restaurantId: restaurantId,
                customerId: customerId,
                isCustomer: true,
              ),
            ),
          );
        },
        child: Text('Go to Chat'),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
// class MenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   MenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _MenuScreenState createState() => _MenuScreenState();
// }
//
// class _MenuScreenState extends State<MenuScreen> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Widget> _screens = <Widget>[
//       MenuTab(restaurantId: widget.restaurantId),
//       ReviewTab(restaurantId: widget.restaurantId),
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.restaurantName),
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
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.restaurant_menu),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.rate_review),
//             label: 'Reviews',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
//
// class MenuTab extends StatefulWidget {
//   final String restaurantId;
//
//   MenuTab({required this.restaurantId});
//
//   @override
//   _MenuTabState createState() => _MenuTabState();
// }
//
// class _MenuTabState extends State<MenuTab> {
//   String _sortOrder = 'asc'; // Default sorting order
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Sort by:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'asc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'asc';
//                       });
//                     },
//                     child: Text(
//                       'Price: Low to High',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'desc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'desc';
//                       });
//                     },
//                     child: Text(
//                       'Price: High to Low',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder(
//             stream: FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}').onValue,
//             builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error loading menu'));
//               }
//               if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
//                 return Center(child: Text('No menu available'));
//               }
//
//               Map<dynamic, dynamic> menuData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//               List<MenuItem> menuItems = menuData.entries.map((e) {
//                 final item = Map<String, dynamic>.from(e.value);
//                 return MenuItem.fromMap(e.key, item);
//               }).toList();
//               menuItems = menuItems.where((item) => item.available).toList(); // Filter out unavailable items
//               menuItems = sortMenuItems(menuItems); // Sort the menu items
//
//               return ListView.builder(
//                 itemCount: menuItems.length,
//                 itemBuilder: (context, index) {
//                   MenuItem menuItem = menuItems[index];
//                   print('Image URL: ${menuItem.imageUrl}'); // Debugging: Log the image URL
//
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Color(0xFFFF9A8B),
//                         backgroundImage: menuItem.imageUrl.isNotEmpty
//                             ? NetworkImage(menuItem.imageUrl)
//                             : null,
//                         child: menuItem.imageUrl.isEmpty
//                             ? Text(
//                           menuItem.name[0],
//                           style: TextStyle(color: Colors.white),
//                         )
//                             : null,
//                       ),
//                       title: Text(menuItem.name),
//                       subtitle: Text(menuItem.description),
//                       trailing: Text('PKR ${menuItem.price.toStringAsFixed(2)}'), // Ensure price is formatted correctly
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   List<MenuItem> sortMenuItems(List<MenuItem> menuItems) {
//     if (_sortOrder == 'asc') {
//       menuItems.sort((a, b) => a.price.compareTo(b.price));
//     } else {
//       menuItems.sort((a, b) => b.price.compareTo(a.price));
//     }
//     return menuItems;
//   }
// }
//
// class ReviewTab extends StatelessWidget {
//   final String restaurantId;
//
//   ReviewTab({required this.restaurantId});
//
//   @override
//   Widget build(BuildContext context) {
//     // This is just a placeholder. Replace with actual review fetching and display logic.
//     return Center(
//       child: Text(
//         'Reviews for $restaurantId',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
//
//













// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
// class MenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   MenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _MenuScreenState createState() => _MenuScreenState();
// }
//
// class _MenuScreenState extends State<MenuScreen> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Widget> _screens = <Widget>[
//       MenuTab(restaurantId: widget.restaurantId),
//       ReviewTab(restaurantId: widget.restaurantId),
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.restaurantName),
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
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.restaurant_menu),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.rate_review),
//             label: 'Reviews',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
//
// class MenuTab extends StatefulWidget {
//   final String restaurantId;
//
//   MenuTab({required this.restaurantId});
//
//   @override
//   _MenuTabState createState() => _MenuTabState();
// }
//
// class _MenuTabState extends State<MenuTab> {
//   String _sortOrder = 'asc'; // Default sorting order
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Sort by:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'asc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'asc';
//                       });
//                     },
//                     child: Text(
//                       'Price: Low to High',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'desc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'desc';
//                       });
//                     },
//                     child: Text(
//                       'Price: High to Low',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder(
//             stream: FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}').onValue,
//             builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error loading menu'));
//               }
//               if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
//                 return Center(child: Text('No menu available'));
//               }
//
//               Map<dynamic, dynamic> menuData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//               List<MenuItem> menuItems = menuData.entries.map((e) {
//                 final item = Map<String, dynamic>.from(e.value);
//                 return MenuItem.fromMap(e.key, item);
//               }).toList();
//               menuItems = menuItems.where((item) => item.available).toList(); // Filter out unavailable items
//               menuItems = sortMenuItems(menuItems); // Sort the menu items
//
//               return ListView.builder(
//                 itemCount: menuItems.length,
//                 itemBuilder: (context, index) {
//                   MenuItem menuItem = menuItems[index];
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Color(0xFFFF9A8B),
//                         backgroundImage: menuItem.imageUrl.isNotEmpty
//                             ? NetworkImage(menuItem.imageUrl)
//                             : null,
//                         child: menuItem.imageUrl.isEmpty
//                             ? Text(
//                           menuItem.name[0],
//                           style: TextStyle(color: Colors.white),
//                         )
//                             : null,
//                       ),
//                       title: Text(menuItem.name),
//                       subtitle: Text(menuItem.description),
//                       trailing: Text('PKR ${menuItem.price.toStringAsFixed(2)}'), // Ensure price is formatted correctly
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   List<MenuItem> sortMenuItems(List<MenuItem> menuItems) {
//     if (_sortOrder == 'asc') {
//       menuItems.sort((a, b) => a.price.compareTo(b.price));
//     } else {
//       menuItems.sort((a, b) => b.price.compareTo(a.price));
//     }
//     return menuItems;
//   }
// }
//
// class ReviewTab extends StatelessWidget {
//   final String restaurantId;
//
//   ReviewTab({required this.restaurantId});
//
//   @override
//   Widget build(BuildContext context) {
//     // This is just a placeholder. Replace with actual review fetching and display logic.
//     return Center(
//       child: Text(
//         'Reviews for $restaurantId',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
//






// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
// class MenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   MenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _MenuScreenState createState() => _MenuScreenState();
// }
//
// class _MenuScreenState extends State<MenuScreen> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Widget> _screens = <Widget>[
//       MenuTab(restaurantId: widget.restaurantId),
//       ReviewTab(restaurantId: widget.restaurantId),
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.restaurantName),
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
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.restaurant_menu),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.rate_review),
//             label: 'Reviews',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
//
// class MenuTab extends StatefulWidget {
//   final String restaurantId;
//
//   MenuTab({required this.restaurantId});
//
//   @override
//   _MenuTabState createState() => _MenuTabState();
// }
//
// class _MenuTabState extends State<MenuTab> {
//   String _sortOrder = 'asc'; // Default sorting order
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Sort by:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'asc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'asc';
//                       });
//                     },
//                     child: Text(
//                       'Price: Low to High',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'desc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'desc';
//                       });
//                     },
//                     child: Text(
//                       'Price: High to Low',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder(
//             stream: FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}').onValue,
//             builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error loading menu'));
//               }
//               if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
//                 return Center(child: Text('No menu available'));
//               }
//
//               Map<dynamic, dynamic> menuData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//               List<MenuItem> menuItems = menuData.entries.map((e) {
//                 final item = Map<String, dynamic>.from(e.value);
//                 return MenuItem.fromMap(e.key, item);
//               }).toList();
//               menuItems = menuItems.where((item) => item.available).toList(); // Filter out unavailable items
//               menuItems = sortMenuItems(menuItems); // Sort the menu items
//
//               return ListView.builder(
//                 itemCount: menuItems.length,
//                 itemBuilder: (context, index) {
//                   MenuItem menuItem = menuItems[index];
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Color(0xFFFF9A8B),
//                         backgroundImage: menuItem.imageUrl.isNotEmpty
//                             ? NetworkImage(menuItem.imageUrl)
//                             : null,
//                         child: menuItem.imageUrl.isEmpty
//                             ? Text(
//                           menuItem.name[0],
//                           style: TextStyle(color: Colors.white),
//                         )
//                             : null,
//                       ),
//                       title: Text(menuItem.name),
//                       subtitle: Text(menuItem.description),
//                       trailing: Text('PKR ${menuItem.price.toStringAsFixed(2)}'), // Ensure price is formatted correctly
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   List<MenuItem> sortMenuItems(List<MenuItem> menuItems) {
//     if (_sortOrder == 'asc') {
//       menuItems.sort((a, b) => a.price.compareTo(b.price));
//     } else {
//       menuItems.sort((a, b) => b.price.compareTo(a.price));
//     }
//     return menuItems;
//   }
// }
//
// class ReviewTab extends StatelessWidget {
//   final String restaurantId;
//
//   ReviewTab({required this.restaurantId});
//
//   @override
//   Widget build(BuildContext context) {
//     // This is just a placeholder. Replace with actual review fetching and display logic.
//     return Center(
//       child: Text(
//         'Reviews for $restaurantId',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
// class MenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   MenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _MenuScreenState createState() => _MenuScreenState();
// }
//
// class _MenuScreenState extends State<MenuScreen> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Widget> _screens = <Widget>[
//       MenuTab(restaurantId: widget.restaurantId),
//       ReviewTab(restaurantId: widget.restaurantId),
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.restaurantName),
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
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.restaurant_menu),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.rate_review),
//             label: 'Reviews',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
//
// class MenuTab extends StatefulWidget {
//   final String restaurantId;
//
//   MenuTab({required this.restaurantId});
//
//   @override
//   _MenuTabState createState() => _MenuTabState();
// }
//
// class _MenuTabState extends State<MenuTab> {
//   String _sortOrder = 'asc'; // Default sorting order
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Sort by:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'asc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'asc';
//                       });
//                     },
//                     child: Text(
//                       'Price: Low to High',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'desc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'desc';
//                       });
//                     },
//                     child: Text(
//                       'Price: High to Low',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: StreamBuilder(
//             stream: FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}').onValue,
//             builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error loading menu'));
//               }
//               if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
//                 return Center(child: Text('No menu available'));
//               }
//
//               Map<dynamic, dynamic> menuData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//               List<MenuItem> menuItems = menuData.entries.map((e) {
//                 final item = Map<String, dynamic>.from(e.value);
//                 return MenuItem.fromMap(e.key, item);
//               }).toList();
//               menuItems = menuItems.where((item) => item.available).toList(); // Filter out unavailable items
//               menuItems = sortMenuItems(menuItems); // Sort the menu items
//
//               return ListView.builder(
//                 itemCount: menuItems.length,
//                 itemBuilder: (context, index) {
//                   MenuItem menuItem = menuItems[index];
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Color(0xFFFF9A8B),
//                         child: Text(
//                           menuItem.name[0],
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       title: Text(menuItem.name),
//                       subtitle: Text(menuItem.description),
//                       trailing: Text('PKR ${menuItem.price.toStringAsFixed(2)}'), // Ensure price is formatted correctly
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   List<MenuItem> sortMenuItems(List<MenuItem> menuItems) {
//     if (_sortOrder == 'asc') {
//       menuItems.sort((a, b) => a.price.compareTo(b.price));
//     } else {
//       menuItems.sort((a, b) => b.price.compareTo(a.price));
//     }
//     return menuItems;
//   }
// }
//
// class ReviewTab extends StatelessWidget {
//   final String restaurantId;
//
//   ReviewTab({required this.restaurantId});
//
//   @override
//   Widget build(BuildContext context) {
//     // This is just a placeholder. Replace with actual review fetching and display logic.
//     return Center(
//       child: Text(
//         'Reviews for $restaurantId',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
// class MenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   MenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _MenuScreenState createState() => _MenuScreenState();
// }
//
// class _MenuScreenState extends State<MenuScreen> {
//   int _selectedIndex = 0;
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     List<Widget> _screens = <Widget>[
//       MenuTab(restaurantId: widget.restaurantId),
//       ReviewTab(restaurantId: widget.restaurantId),
//     ];
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.restaurantName),
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
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.restaurant_menu),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.rate_review),
//             label: 'Reviews',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
//
// class MenuTab extends StatefulWidget {
//   final String restaurantId;
//
//   MenuTab({required this.restaurantId});
//
//   @override
//   _MenuTabState createState() => _MenuTabState();
// }
//
// class _MenuTabState extends State<MenuTab> {
//   List<MenuItem> menuItems = [];
//   String _sortOrder = 'asc'; // Default sorting order
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Sort by:',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'asc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'asc';
//                         sortMenuItems();
//                       });
//                     },
//                     child: Text(
//                       'Price: Low to High',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 10),
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _sortOrder == 'desc' ? Color(0xFFFF9A8B) : Colors.grey,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _sortOrder = 'desc';
//                         sortMenuItems();
//                       });
//                     },
//                     child: Text(
//                       'Price: High to Low',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Expanded(
//           child: FutureBuilder<DataSnapshot>(
//             future: FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}').get(),
//             builder: (context, snapshot) {
//               if (snapshot.connectionState == ConnectionState.waiting) {
//                 return Center(child: CircularProgressIndicator());
//               }
//               if (snapshot.hasError) {
//                 return Center(child: Text('Error loading menu'));
//               }
//               if (!snapshot.hasData || !snapshot.data!.exists) {
//                 return Center(child: Text('No menu available'));
//               }
//
//               Map<dynamic, dynamic> menuData = snapshot.data!.value as Map<dynamic, dynamic>;
//               menuItems = menuData.values.map((e) => MenuItem.fromMap(e)).toList();
//               sortMenuItems();
//
//               return ListView.builder(
//                 itemCount: menuItems.length,
//                 itemBuilder: (context, index) {
//                   MenuItem menuItem = menuItems[index];
//                   return Card(
//                     margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//                     elevation: 5,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     child: ListTile(
//                       leading: CircleAvatar(
//                         backgroundColor: Color(0xFFFF9A8B),
//                         child: Text(
//                           menuItem.name[0],
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       title: Text(menuItem.name),
//                       subtitle: Text(menuItem.description),
//                       trailing: Text('PKR ${menuItem.price}'),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
//
//   void sortMenuItems() {
//     if (_sortOrder == 'asc') {
//       menuItems.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
//     } else {
//       menuItems.sort((a, b) => double.parse(b.price).compareTo(double.parse(a.price)));
//     }
//   }
// }
//
// class ReviewTab extends StatelessWidget {
//   final String restaurantId;
//
//   ReviewTab({required this.restaurantId});
//
//   @override
//   Widget build(BuildContext context) {
//     // This is just a placeholder. Replace with actual review fetching and display logic.
//     return Center(
//       child: Text(
//         'Reviews for $restaurantId',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
// }
