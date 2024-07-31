import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../Screens/RoleSelectionScreen.dart';
import 'CustomerMenuScreen.dart';
import 'CustomerAllRestaurantScreen.dart';
import '../../Models/MenuItem.dart';
import '../../Models/Restaurant.dart';
import 'CustomerChatListScreen.dart'; // Add this import

class CustomerHomeScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  CustomerHomeScreen({required this.customerId,required this.customerName});

  @override
  _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  List<Restaurant> restaurants = [];
  bool isLoading = true;
  late String customerId;
  late String customerName;
  int _selectedIndex = 0; // Add this line

  @override
  void initState() {
    super.initState();
    fetchRestaurants();
    customerId = widget.customerId;
    customerName = widget.customerName;

  }

  Future<void> fetchRestaurants() async {
    final snapshot = await database.child('restaurant_users').get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> restaurantData = snapshot.value as Map<dynamic, dynamic>;
      List<Restaurant> tempRestaurants = [];
      restaurantData.forEach((key, value) {
        Restaurant restaurant = Restaurant.fromMap(value);
        tempRestaurants.add(restaurant);
      });
      setState(() {
        restaurants = tempRestaurants;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail'); // Retrieve the user's email from SharedPreferences

    if (userEmail != null) {
      // Update Firebase to set isLoggedIn to false
      DatabaseReference ref = FirebaseDatabase.instance.ref("customers");
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    switch (_selectedIndex) {
      case 1:
        currentScreen = CustomerChatListScreen(customerId: customerId);
        break;
      case 2:
        currentScreen = Container(); // Placeholder for Price Comparison Screen
        break;
      case 0:
      default:
        currentScreen = HomePage(restaurants: restaurants, customerId: customerId,customerName: customerName,);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('BudgetBites'),
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
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : currentScreen, // Update this line
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare),
            label: 'Price Comparison',
          ),
        ],
        currentIndex: _selectedIndex, // Update this line
        selectedItemColor: Color(0xFFFF9A8B),
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Restaurant> restaurants;
  final String customerId;
  final String customerName;

  HomePage({required this.restaurants, required this.customerId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StaggeredGridView.countBuilder(
              shrinkWrap: true,
              crossAxisCount: 4,
              itemCount: 4,
              itemBuilder: (BuildContext context, int index) => CategoryCard(
                title: _getCategoryTitle(index),
              ),
              staggeredTileBuilder: (int index) =>
                  StaggeredTile.count(2, index.isEven ? 2.5 : 1.5),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Restaurants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllRestaurantsPage(
                          restaurants: restaurants,
                          customerId: customerId,
                          customerName: customerName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: Color(0xFFFF9A8B),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          restaurants.isNotEmpty
              ? CarouselSlider.builder(
            itemCount: restaurants.length,
            itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
                RestaurantTile(
                  restaurant: restaurants[itemIndex],
                  customerId: customerId,
                  customerName:customerName ,
                ),
            options: CarouselOptions(
              height: 180,
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 0.8,
            ),
          )
              : Center(child: Text('No Restaurants Available')),
        ],
      ),
    );
  }

  String _getCategoryTitle(int index) {
    switch (index) {
      case 0:
        return 'Top Rated';
      case 1:
        return 'Hygienic';
      case 2:
        return 'Recommended';
      case 3:
        return 'Popular';
      default:
        return 'Category';
    }
  }
}

class CategoryCard extends StatelessWidget {
  final String title;

  CategoryCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  final String customerId;
  final String customerName;


  RestaurantTile({required this.restaurant, required this.customerId,required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFFF9A8B),
          child: Icon(Icons.restaurant, color: Colors.white),
        ),
        title: Text(
          restaurant.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9A8B),
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFFFF9A8B)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                restaurantId: restaurant.restaurantId,
                restaurantName: restaurant.name,
                customerId: customerId,
                customerName:customerName ,
              ),
            ),
          );
        },
      ),
    );
  }
}












// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import '../../Screens/RoleSelectionScreen.dart'; // Correct the missing semicolon here
// import 'CustomerMenuScreen.dart';
// import 'CustomerAllRestaurantScreen.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
// class CustomerHomeScreen extends StatefulWidget {
//   final String customerId;
//
//   CustomerHomeScreen({required this.customerId});
//
//   @override
//   _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
// }
//
// class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
//   final DatabaseReference database = FirebaseDatabase.instance.ref();
//   List<Restaurant> restaurants = [];
//   bool isLoading = true;
//   late String customerId;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchRestaurants();
//     customerId = widget.customerId;
//
//   }
//
//   Future<void> fetchRestaurants() async {
//     final snapshot = await database.child('restaurant_users').get();
//     if (snapshot.exists) {
//       Map<dynamic, dynamic> restaurantData = snapshot.value as Map<dynamic, dynamic>;
//       List<Restaurant> tempRestaurants = [];
//       restaurantData.forEach((key, value) {
//         Restaurant restaurant = Restaurant.fromMap(value);
//         tempRestaurants.add(restaurant);
//       });
//       setState(() {
//         restaurants = tempRestaurants;
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _signOut() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? userEmail = prefs.getString('userEmail'); // Retrieve the user's email from SharedPreferences
//
//     if (userEmail != null) {
//       // Update Firebase to set isLoggedIn to false
//       DatabaseReference ref = FirebaseDatabase.instance.ref("customers");
//       DatabaseEvent event = await ref.orderByChild("email").equalTo(userEmail).once();
//       DataSnapshot snapshot = event.snapshot;
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
//   void _onItemTapped(int index) {
//     setState(() {
//       // Add logic to switch between screens if needed
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('BudgetBites'),
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
//         actions: <Widget>[
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: _signOut,
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator())
//           : HomePage(restaurants: restaurants,customerId: customerId,),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: 'Chat',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.compare),
//             label: 'Price Comparison',
//           ),
//         ],
//         currentIndex: 0,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//         backgroundColor: Colors.white,
//         unselectedItemColor: Colors.grey,
//       ),
//     );
//   }
// }
//
// class HomePage extends StatelessWidget {
//   final List<Restaurant> restaurants;
//   final String customerId;
//
//   HomePage({required this.restaurants,required this.customerId});
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: <Widget>[
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: StaggeredGridView.countBuilder(
//               shrinkWrap: true,
//               crossAxisCount: 4,
//               itemCount: 4,
//               itemBuilder: (BuildContext context, int index) => CategoryCard(
//                 title: _getCategoryTitle(index),
//               ),
//               staggeredTileBuilder: (int index) =>
//                   StaggeredTile.count(2, index.isEven ? 2.5 : 1.5),
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Restaurants',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => AllRestaurantsPage(restaurants: restaurants,customerId: customerId,),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     'See All',
//                     style: TextStyle(
//                       color: Color(0xFFFF9A8B),
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           restaurants.isNotEmpty
//               ? CarouselSlider.builder(
//             itemCount: restaurants.length,
//             itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
//                 RestaurantTile(
//                   restaurant: restaurants[itemIndex],
//                   customerId: customerId,
//                 ),
//             options: CarouselOptions(
//               height: 180,
//               autoPlay: true,
//               enlargeCenterPage: true,
//               viewportFraction: 0.8,
//             ),
//           )
//               : Center(child: Text('No Restaurants Available')),
//         ],
//       ),
//     );
//   }
//
//   String _getCategoryTitle(int index) {
//     switch (index) {
//       case 0:
//         return 'Top Rated';
//       case 1:
//         return 'Hygienic';
//       case 2:
//         return 'Recommended';
//       case 3:
//         return 'Popular';
//       default:
//         return 'Category';
//     }
//   }
// }
//
// class CategoryCard extends StatelessWidget {
//   final String title;
//
//   CategoryCard({required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class RestaurantTile extends StatelessWidget {
//   final Restaurant restaurant;
//   final String customerId;
//
//   RestaurantTile({required this.restaurant,required this.customerId});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
//       elevation: 5,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Color(0xFFFF9A8B),
//           child: Icon(Icons.restaurant, color: Colors.white),
//         ),
//         title: Text(
//           restaurant.name,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Color(0xFFFF9A8B),
//           ),
//         ),
//         trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFFFF9A8B)),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => MenuScreen(restaurantId: restaurant.restaurantId, restaurantName: restaurant.name,customerId: customerId,),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }















// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'CustomerMenuScreen.dart';
// import 'CustomerAllRestaurantScreen.dart';
// import '../../Models/MenuItem.dart';
// import '../../Models/Restaurant.dart';
//
//
// class CustomerHomeScreen extends StatefulWidget {
//   @override
//   _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
// }
//
// class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
//   final DatabaseReference database = FirebaseDatabase.instance.ref();
//   List<Restaurant> restaurants = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchRestaurants();
//   }
//
//   Future<void> fetchRestaurants() async {
//     final snapshot = await database.child('restaurant_users').get();
//     if (snapshot.exists) {
//       Map<dynamic, dynamic> restaurantData = snapshot.value as Map<dynamic, dynamic>;
//       List<Restaurant> tempRestaurants = [];
//       restaurantData.forEach((key, value) {
//         Restaurant restaurant = Restaurant.fromMap(value);
//         tempRestaurants.add(restaurant);
//       });
//       setState(() {
//         restaurants = tempRestaurants;
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   void _onItemTapped(int index) {
//     setState(() {
//       // Add logic to switch between screens if needed
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('BudgetBites'),
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
//           : HomePage(restaurants: restaurants),
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat),
//             label: 'Chat',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.compare),
//             label: 'Price Comparison',
//           ),
//         ],
//         currentIndex: 0,
//         selectedItemColor: Color(0xFFFF9A8B),
//         onTap: _onItemTapped,
//         backgroundColor: Colors.white,
//         unselectedItemColor: Colors.grey,
//       ),
//     );
//   }
// }
//
// class HomePage extends StatelessWidget {
//   final List<Restaurant> restaurants;
//
//   HomePage({required this.restaurants});
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: <Widget>[
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: StaggeredGridView.countBuilder(
//               shrinkWrap: true,
//               crossAxisCount: 4,
//               itemCount: 4,
//               itemBuilder: (BuildContext context, int index) => CategoryCard(
//                 title: _getCategoryTitle(index),
//               ),
//               staggeredTileBuilder: (int index) =>
//                   StaggeredTile.count(2, index.isEven ? 2.5 : 1.5),
//               mainAxisSpacing: 10,
//               crossAxisSpacing: 10,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Restaurants',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => AllRestaurantsPage(restaurants: restaurants),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     'See All',
//                     style: TextStyle(
//                       color: Color(0xFFFF9A8B),
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           restaurants.isNotEmpty
//               ? CarouselSlider.builder(
//             itemCount: restaurants.length,
//             itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) =>
//                 RestaurantTile(
//                   restaurant: restaurants[itemIndex],
//                 ),
//             options: CarouselOptions(
//               height: 180,
//               autoPlay: true,
//               enlargeCenterPage: true,
//               viewportFraction: 0.8,
//             ),
//           )
//               : Center(child: Text('No Restaurants Available')),
//         ],
//       ),
//     );
//   }
//
//   String _getCategoryTitle(int index) {
//     switch (index) {
//       case 0:
//         return 'Top Rated';
//       case 1:
//         return 'Hygienic';
//       case 2:
//         return 'Recommended';
//       case 3:
//         return 'Popular';
//       default:
//         return 'Category';
//     }
//   }
// }
//
// class CategoryCard extends StatelessWidget {
//   final String title;
//
//   CategoryCard({required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               title,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
