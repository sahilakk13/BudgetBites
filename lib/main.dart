import 'package:bb/Screens/CustomerScreens/CustomerHomeScreen.dart';
import 'package:bb/Screens/HomeScreen.dart';
import 'package:bb/Screens/RestaurentScreens/RestaurantHomeScreen.dart';
import 'package:bb/Screens/SignInScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Screens/RoleSelectionScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; // Import SharedPreferences

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get SharedPreferences instance
  SharedPreferences prefs = await SharedPreferences.getInstance();


  // Check if user is logged in
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  // Determine the initial route based on login status
  Widget initialScreen;
  if (isLoggedIn) {
    // Retrieve user type from SharedPreferences
    String userType = prefs.getString('userType') ?? 'customer';
    String restauranrId = prefs.getString('restaurant_id') ?? 'nill' ;
    String restauranrName = prefs.getString('restaurant_name') ?? 'nill' ;
    String customerId = prefs.getString('customerId') ?? 'nill' ;
    String customerName = prefs.getString('customerName') ?? 'nill' ;



    // Navigate to the appropriate home screen based on user type
    if (userType == 'restaurant') {
      initialScreen = RestaurantHomeScreen(restaurantId: restauranrId,restaurantName: restauranrName,);
    } else {
      initialScreen = CustomerHomeScreen(customerId: customerId,customerName: customerName,); // Assuming HomeScreen is for customers
    }
  } else {
    initialScreen = RoleSelectionScreen();
  }

  runApp(BudgetBitesApp(initialScreen: initialScreen));
}

class BudgetBitesApp extends StatelessWidget {
  final Widget initialScreen;

  BudgetBitesApp({required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetBites',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: initialScreen,
    );
  }
}







// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:bb/Screens/RestaurantHomeScreen.dart';
// import 'package:bb/Screens/SignInScreen.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'Screens/RoleSelectionScreen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   runApp(BudgetBitesApp());
// }
//
// class BudgetBitesApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'BudgetBites',
//       theme: ThemeData(
//         primarySwatch: Colors.green,
//       ),
//       home: RoleSelectionScreen(),
//     );
//   }
// }
