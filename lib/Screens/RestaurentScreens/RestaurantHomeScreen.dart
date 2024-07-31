import 'package:bb/Screens/RestaurentScreens/RestaurantChatListScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bb/Screens/RestaurentScreens/RestaurantAddMenuScreen.dart';
import 'package:bb/Screens/RoleSelectionScreen.dart'; // Import the RoleSelectionScreen

class RestaurantHomeScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  RestaurantHomeScreen({required this.restaurantId,required this.restaurantName});

  @override
  _RestaurantHomeScreenState createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
  late String id;
  late String restaurentName;
  int _selectedIndex = 0;


  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    id = widget.restaurantId;
    restaurentName=widget.restaurantName;

    // Initialize the widget options after id is available
    _widgetOptions = <Widget>[
      AddMenuScreen(restaurantId: id,restaurantName: restaurentName,),
      CustomerReviewsScreen(),
      RestaurantChatListScreen(restaurantId: id),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail'); // Retrieve the user's email from SharedPreferences

    if (userEmail != null) {
      // Update Firebase to set isLoggedIn to false
      DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
      DatabaseEvent event = await ref.orderByChild("email").equalTo(userEmail).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        final data = snapshot.children.first.ref;
        await data.update({"isLoggedIn": false});
      }

      // Clear SharedPreferences
      await prefs.clear();

      // Navigate to Role Selection Screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
            (Route<dynamic> route) => false,
      );
    } else {
      // Handle the case where userEmail is null if needed
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Center(
          child: Text(
            "BudgetBites",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews),
            label: 'Customer Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Customer Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class CustomerReviewsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Customer Reviews Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

class CustomerChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Customer Chat Screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}






// import 'package:bb/Screens/RestaurantAddMenuScreen.dart';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:bb/Screens/RoleSelectionScreen.dart'; // Import the RoleSelectionScreen
//
// class RestaurantHomeScreen extends StatefulWidget {
//   final String restaurantId;
//
//   RestaurantHomeScreen({required this.restaurantId});
//   @override
//   _RestaurantHomeScreenState createState() => _RestaurantHomeScreenState();
// }
//
// class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
//   String id="null";
//   @override
//   void initState() {
//     // TODO: implement initState
//     id = widget.restaurantId;
//   }
//   int _selectedIndex = 0;
//   late DataSnapshot snapshot;
//
//
//
//
//   static List<Widget> _widgetOptions = <Widget>[
//     AddMenuScreen(restaurantId:id,),
//     CustomerReviewsScreen(),
//     CustomerChatScreen(),
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   Future<void> _signOut() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? userEmail = prefs.getString('userEmail'); // Retrieve the user's email from SharedPreferences
//
//     if (userEmail != null) {
//       // Update Firebase to set isLoggedIn to false
//       DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
//       DatabaseEvent event = await ref.orderByChild("email").equalTo(userEmail).once();
//       snapshot = event.snapshot;
//
//       if (snapshot.exists) {
//         final data = snapshot.children.first.ref;
//         await data.update({"isLoggedIn": false});
//       }
//
//       // Clear SharedPreferences
//       await prefs.clear();
//
//       // Navigate to Role Selection Screen
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
//             (Route<dynamic> route) => false,
//       );
//     } else {
//       // Handle the case where userEmail is null if needed
//       Navigator.of(context).pushAndRemoveUntil(
//         MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
//             (Route<dynamic> route) => false,
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Center(
//           child: Text(
//             "BudgetBites",
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//         ),
//         actions: <Widget>[
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: _signOut,
//           ),
//         ],
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//         ),
//       ),
//       body: Center(
//         child: _widgetOptions.elementAt(_selectedIndex),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         items: <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.menu_book),
//             label: 'Menu',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.reviews),
//             label: 'Customer Reviews',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: 'Customer Chat',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Colors.amber[800],
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
//
// class CustomerReviewsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Text(
//           'Customer Reviews Screen',
//           style: TextStyle(fontSize: 24),
//         ),
//       ),
//     );
//   }
// }
//
// class CustomerChatScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Text(
//           'Customer Chat Screen',
//           style: TextStyle(fontSize: 24),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
// // import 'package:bb/Screens/RestaurantAddMenuScreen.dart';
// // import 'package:flutter/material.dart';
// //
// // class RestaurantHomeScreen extends StatefulWidget {
// //   @override
// //   _RestaurantHomeScreenState createState() => _RestaurantHomeScreenState();
// // }
// //
// // class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
// //   int _selectedIndex = 0;
// //
// //   static List<Widget> _widgetOptions = <Widget>[
// //     AddMenuScreen(),
// //     CustomerReviewsScreen(),
// //     CustomerChatScreen(),
// //   ];
// //
// //   void _onItemTapped(int index) {
// //     setState(() {
// //       _selectedIndex = index;
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: Colors.transparent,
// //         elevation: 0,
// //         title: Center(
// //           child: Text(
// //             "BudgetBItes",
// //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
// //           ),
// //         ),
// //         flexibleSpace: Container(
// //           decoration: BoxDecoration(
// //             gradient: LinearGradient(
// //               colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
// //               begin: Alignment.topCenter,
// //               end: Alignment.bottomCenter,
// //             ),
// //           ),
// //         ),
// //       ),
// //       body: Center(
// //         child: _widgetOptions.elementAt(_selectedIndex),
// //       ),
// //       bottomNavigationBar: BottomNavigationBar(
// //         items: <BottomNavigationBarItem>[
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.menu_book),
// //             label: 'Menu',
// //           ),
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.reviews),
// //             label: 'Customer Reviews',
// //           ),
// //           BottomNavigationBarItem(
// //             icon: Icon(Icons.chat),
// //             label: 'Customer Chat',
// //           ),
// //         ],
// //         currentIndex: _selectedIndex,
// //         selectedItemColor: Colors.amber[800],
// //         onTap: _onItemTapped,
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// // class CustomerReviewsScreen extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Center(
// //         child: Text(
// //           'Customer Reviews Screen',
// //           style: TextStyle(fontSize: 24),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // class CustomerChatScreen extends StatelessWidget {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Center(
// //         child: Text(
// //           'Customer Chat Screen',
// //           style: TextStyle(fontSize: 24),
// //         ),
// //       ),
// //     );
// //   }
// // }
