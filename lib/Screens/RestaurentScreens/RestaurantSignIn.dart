import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'RestaurantSignUpScreen.dart';
import 'RestaurantHomeScreen.dart';
import '../../views/reusable_widgets.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RestaurantSignInScreen extends StatefulWidget {
  const RestaurantSignInScreen({super.key});

  @override
  State<RestaurantSignInScreen> createState() => _RestaurantSignInScreenState();
}

class _RestaurantSignInScreenState extends State<RestaurantSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    logoWidget('assets/logot.png'),
                    SizedBox(height: 30),
                    reusableTextField(
                      "Enter Email",
                      Icons.person_outline,
                      false,
                      _emailTextController,
                          (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    reusableTextField(
                      "Enter Password",
                      Icons.lock_outline,
                      true,
                      _passwordTextController,
                          (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    SizedBox(height: 20),
                    signInSignUpButton(context, true, () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          errorMessage = null;
                        });
                        _signIn();
                      }
                    }),
                    signUpOption(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Signing in..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Use Firebase Realtime Database to verify email and password
      DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
      DatabaseEvent event = await ref.orderByChild("email").equalTo(_emailTextController.text).once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        final data = snapshot.children.first.value as Map<dynamic, dynamic>;
        String storedPasswordHash = data['password'];
        String restaurantId = data['restaurant_id'];
        String restaurantName = data['restaurant_name'];
        String enteredPasswordHash = _hashPassword(_passwordTextController.text);

        if (storedPasswordHash == enteredPasswordHash) {
          // Update the user's last sign-in time and isLoggedIn flag
          DatabaseReference userRef = snapshot.children.first.ref;
          await userRef.update({
            "last_sign_in": DateTime.now().toIso8601String(),
            "isLoggedIn": true,
          });

          // Store login status and email in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', _emailTextController.text);
          await prefs.setString('userType', 'restaurant');
          await prefs.setString('restaurant_id', restaurantId);

          Navigator.pop(context); // Close the loading dialog
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => RestaurantHomeScreen(restaurantId: restaurantId,restaurantName: restaurantName,)),
                  (Route<dynamic> route) => false);
        } else {
          throw Exception('Wrong password');
        }
      } else {
        throw Exception('No user found for that email.');
      }
    } catch (error) {
      Navigator.pop(context); // Close the loading dialog
      setState(() {
        errorMessage = getErrorMessage(error.toString());
      });
      print("Error ${error.toString()}");
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Hash the bytes
    return digest.toString(); // Convert hash to string
  }

  String getErrorMessage(String errorCode) {
    if (errorCode.contains('Wrong password')) {
      return 'Wrong password provided.';
    } else if (errorCode.contains('No user found')) {
      return 'No user found for that email.';
    }
    return 'An error occurred. Please try again.';
  }

  Image logoWidget(String imageName) {
    return Image.asset(
      imageName,
      fit: BoxFit.contain,
      width: 240,
      height: 240,
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?",
            style: TextStyle(color: Colors.black)),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => RestaurantSignUpScreen()));
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../Screens/RestaurantSignUpScreen.dart';
// import '../Screens/RestaurantHomeScreen.dart';
// import '../views/reusable_widgets.dart';
// import 'package:crypto/crypto.dart';
// import 'dart:convert';
//
// class RestaurantSignInScreen extends StatefulWidget {
//   const RestaurantSignInScreen({super.key});
//
//   @override
//   State<RestaurantSignInScreen> createState() => _RestaurantSignInScreenState();
// }
//
// class _RestaurantSignInScreenState extends State<RestaurantSignInScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordTextController = TextEditingController();
//   final TextEditingController _emailTextController = TextEditingController();
//   String? errorMessage;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     logoWidget('assets/logot.png'),
//                     SizedBox(height: 30),
//                     reusableTextField(
//                       "Enter Email",
//                       Icons.person_outline,
//                       false,
//                       _emailTextController,
//                           (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter an email';
//                         } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     reusableTextField(
//                       "Enter Password",
//                       Icons.lock_outline,
//                       true,
//                       _passwordTextController,
//                           (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter a password';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     if (errorMessage != null)
//                       Text(
//                         errorMessage!,
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     SizedBox(height: 20),
//                     signInSignUpButton(context, true, () {
//                       if (_formKey.currentState!.validate()) {
//                         setState(() {
//                           errorMessage = null;
//                         });
//                         _signIn();
//                       }
//                     }),
//                     signUpOption(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _signIn() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 20),
//                 Text("Signing in..."),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//
//     try {
//       // Use Firebase Realtime Database to verify email and password
//       DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
//       DatabaseEvent event = await ref.orderByChild("email").equalTo(_emailTextController.text).once();
//       DataSnapshot snapshot = event.snapshot;
//       print(event);
//       print(snapshot);
//
//       if (snapshot.exists) {
//         final data = snapshot.children.first.value as Map<dynamic, dynamic>;
//         String storedPasswordHash = data['password'];
//         String enteredPasswordHash = _hashPassword(_passwordTextController.text);
//         print(data);
//         if (storedPasswordHash == enteredPasswordHash) {
//           // Update the user's last sign-in time and isLoggedIn flag
//           DatabaseReference userRef = snapshot.children.first.ref;
//           await userRef.update({
//             "last_sign_in": DateTime.now().toIso8601String(),
//             "isLoggedIn": true,
//           });
//
//           Navigator.pop(context); // Close the loading dialog
//           Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(builder: (context) => RestaurantHomeScreen()),
//                   (Route<dynamic> route) => false);
//         } else {
//           throw Exception('Wrong password');
//         }
//       } else {
//         throw Exception('No user found for that email.');
//       }
//     } catch (error) {
//       Navigator.pop(context); // Close the loading dialog
//       setState(() {
//         errorMessage = getErrorMessage(error.toString());
//       });
//       print("Error ${error.toString()}");
//     }
//   }
//
//
//   String _hashPassword(String password) {
//     final bytes = utf8.encode(password); // Convert password to bytes
//     final digest = sha256.convert(bytes); // Hash the bytes
//     return digest.toString(); // Convert hash to string
//   }
//
//   String getErrorMessage(String errorCode) {
//     if (errorCode.contains('Wrong password')) {
//       return 'Wrong password provided.';
//     } else if (errorCode.contains('No user found')) {
//       return 'No user found for that email.';
//     }
//     return 'An error occurred. Please try again.';
//   }
//
//   Image logoWidget(String imageName) {
//     return Image.asset(
//       imageName,
//       fit: BoxFit.contain,
//       width: 240,
//       height: 240,
//     );
//   }
//
//   Row signUpOption() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text("Don't have an account?",
//             style: TextStyle(color: Colors.black)),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => RestaurantSignUpScreen()));
//           },
//           child: const Text(
//             " Sign Up",
//             style: TextStyle(
//                 color: Colors.black, fontWeight: FontWeight.bold),
//           ),
//         )
//       ],
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../Screens/RestaurantSignUpScreen.dart';
// import '../Screens/RestaurantHomeScreen.dart';
// import '../views/reusable_widgets.dart';
//
// class RestaurantSignInScreen extends StatefulWidget {
//   const RestaurantSignInScreen({super.key});
//
//   @override
//   State<RestaurantSignInScreen> createState() => _RestaurantSignInScreenState();
// }
//
// class _RestaurantSignInScreenState extends State<RestaurantSignInScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordTextController = TextEditingController();
//   final TextEditingController _emailTextController = TextEditingController();
//   String? errorMessage;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     logoWidget('assets/logot.png'),
//                     SizedBox(height: 30),
//                     reusableTextField(
//                       "Enter Email",
//                       Icons.person_outline,
//                       false,
//                       _emailTextController,
//                           (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter an email';
//                         } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     reusableTextField(
//                       "Enter Password",
//                       Icons.lock_outline,
//                       true,
//                       _passwordTextController,
//                           (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter a password';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     if (errorMessage != null)
//                       Text(
//                         errorMessage!,
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     SizedBox(height: 20),
//                     signInSignUpButton(context, true, () {
//                       if (_formKey.currentState!.validate()) {
//                         setState(() {
//                           errorMessage = null;
//                         });
//                         _signIn();
//                       }
//                     }),
//                     signUpOption(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _signIn() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 20),
//                 Text("Signing in..."),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//
//     try {
//       // Use Firebase Realtime Database to verify email and password
//       DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
//       DatabaseEvent event = await ref.orderByChild("email").equalTo(_emailTextController.text).once();
//       DataSnapshot snapshot = event.snapshot;
//       print(event);
//       print(snapshot);
//
//       if (snapshot.exists) {
//         final data = snapshot.children.first.value as Map<dynamic, dynamic>;
//         print(data);
//         if (data['password'] == _passwordTextController.text) {
//           Navigator.pop(context); // Close the loading dialog
//           Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(builder: (context) => RestaurantHomeScreen()),
//                   (Route<dynamic> route) => false);
//         } else {
//           throw Exception('Wrong password');
//         }
//       } else {
//         throw Exception('No user found for that email.');
//       }
//     } catch (error) {
//       Navigator.pop(context); // Close the loading dialog
//       setState(() {
//         errorMessage = getErrorMessage(error.toString());
//       });
//       print("Error ${error.toString()}");
//     }
//   }
//
//   String getErrorMessage(String errorCode) {
//     if (errorCode.contains('Wrong password')) {
//       return 'Wrong password provided.';
//     } else if (errorCode.contains('No user found')) {
//       return 'No user found for that email.';
//     }
//     return 'An error occurred. Please try again.';
//   }
//
//   Image logoWidget(String imageName) {
//     return Image.asset(
//       imageName,
//       fit: BoxFit.contain,
//       width: 240,
//       height: 240,
//     );
//   }
//
//   Row signUpOption() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text("Don't have an account?",
//             style: TextStyle(color: Colors.black)),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => RestaurantSignUpScreen()));
//           },
//           child: const Text(
//             " Sign Up",
//             style: TextStyle(
//                 color: Colors.black, fontWeight: FontWeight.bold),
//           ),
//         )
//       ],
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../Screens/RestaurantSignUpScreen.dart';
// import '../Screens/RestaurantHomeScreen.dart';
// import '../views/reusable_widgets.dart';
//
// class RestaurantSignInScreen extends StatefulWidget {
//   const RestaurantSignInScreen({super.key});
//
//   @override
//   State<RestaurantSignInScreen> createState() => _RestaurantSignInScreenState();
// }
//
// class _RestaurantSignInScreenState extends State<RestaurantSignInScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordTextController = TextEditingController();
//   final TextEditingController _emailTextController = TextEditingController();
//   String? errorMessage;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     logoWidget('assets/logot.png'),
//                     SizedBox(height: 30),
//                     reusableTextField(
//                       "Enter Email",
//                       Icons.person_outline,
//                       false,
//                       _emailTextController,
//                           (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter an email';
//                         } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     reusableTextField(
//                       "Enter Password",
//                       Icons.lock_outline,
//                       true,
//                       _passwordTextController,
//                           (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter a password';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     if (errorMessage != null)
//                       Text(
//                         errorMessage!,
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     SizedBox(height: 20),
//                     signInSignUputton(context, true, () {
//                       if (_formKey.currentState!.validate()) {
//                         setState(() {
//                           errorMessage = null;
//                         });
//                         _signIn();
//                       }
//                     }),
//                     signUpOption(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _signIn() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 20),
//                 Text("Signing in..."),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//
//     try {
//       // Use Firebase Realtime Database to verify email and password
//       DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
//       DataSnapshot snapshot = await ref.orderByChild("email").equalTo(_emailTextController.text).once();
//
//       if (snapshot.exists) {
//         final data = snapshot.children.first.value as Map<dynamic, dynamic>;
//         if (data['password'] == _passwordTextController.text) {
//           Navigator.pop(context); // Close the loading dialog
//           Navigator.of(context).pushAndRemoveUntil(
//               MaterialPageRoute(builder: (context) => RestaurantHomeScreen()),
//                   (Route<dynamic> route) => false);
//         } else {
//           throw Exception('Wrong password');
//         }
//       } else {
//         throw Exception('No user found for that email.');
//       }
//     } catch (error) {
//       Navigator.pop(context); // Close the loading dialog
//       setState(() {
//         errorMessage = getErrorMessage(error.toString());
//       });
//       print("Error ${error.toString()}");
//     }
//   }
//
//   String getErrorMessage(String errorCode) {
//     if (errorCode.contains('Wrong password')) {
//       return 'Wrong password provided.';
//     } else if (errorCode.contains('No user found')) {
//       return 'No user found for that email.';
//     }
//     return 'An error occurred. Please try again.';
//   }
//
//   Image logoWidget(String imageName) {
//     return Image.asset(
//       imageName,
//       fit: BoxFit.contain,
//       width: 240,
//       height: 240,
//     );
//   }
//
//   Row signUpOption() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Text("Don't have an account?",
//             style: TextStyle(color: Colors.black)),
//         GestureDetector(
//           onTap: () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (context) => RestaurantSignUpScreen()));
//           },
//           child: const Text(
//             " Sign Up",
//             style: TextStyle(
//                 color: Colors.black, fontWeight: FontWeight.bold),
//           ),
//         )
//       ],
//     );
//   }
// }
