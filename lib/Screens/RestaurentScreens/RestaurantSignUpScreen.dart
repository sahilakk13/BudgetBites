import 'package:bb/Screens/HomeScreen.dart';
import 'package:bb/Screens/RestaurentScreens/RestaurantHomeScreen.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../../views/reusable_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestaurantSignUpScreen extends StatefulWidget {
  const RestaurantSignUpScreen({Key? key}) : super(key: key);

  @override
  _RestaurantSignUpScreenState createState() => _RestaurantSignUpScreenState();
}

class _RestaurantSignUpScreenState extends State<RestaurantSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _confirmPasswordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final TextEditingController _locationTextController = TextEditingController();
  final TextEditingController _restaurantNameTextController = TextEditingController();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert the password to bytes
    final digest = sha256.convert(bytes); // Hash the bytes using SHA-256
    return digest.toString(); // Return the hash as a string
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Restaurant Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Username",
                    Icons.person_outline,
                    false,
                    _userNameTextController,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      } else if (value.length < 3) {
                        return 'Username must be at least 3 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Email ID",
                    Icons.email_outlined,
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
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Password",
                    Icons.lock_outlined,
                    true,
                    _passwordTextController,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      } else if (value.length < 5) {
                        return 'Password must be at least 5 characters long';
                      } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
                        return 'Password must include uppercase, lowercase, and special characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Confirm Password",
                    Icons.lock_outlined,
                    true,
                    _confirmPasswordTextController,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      } else if (value != _passwordTextController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Location",
                    Icons.location_on_outlined,
                    false,
                    _locationTextController,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  reusableTextField(
                    "Enter Restaurant Name",
                    Icons.restaurant_menu,
                    false,
                    _restaurantNameTextController,
                        (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the restaurant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  signInSignUpButton(context, false, () async {
                    if (_formKey.currentState!.validate()) {
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
                                  Text("Creating account..."),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      // Hash the password
                      String hashedPassword = _hashPassword(_passwordTextController.text);

                      // Store restaurant information in Realtime Database
                      DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
                      DatabaseEvent event = await ref.orderByChild("email").equalTo(_emailTextController.text).once();
                      DataSnapshot snapshot = event.snapshot;

                      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("restaurant_users");
                      String userId = usersRef.push().key!;

                      if (!snapshot.exists) {
                        usersRef.child(userId).set({
                          "restaurant_id" : userId,
                          "username": _userNameTextController.text,
                          "email": _emailTextController.text,
                          "password": hashedPassword,
                          "location": _locationTextController.text,
                          "restaurant_name": _restaurantNameTextController.text,
                        }).then((_) async {

                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('userType', 'restaurant');
                          await prefs.setBool('isLoggedIn', true);
                          await prefs.setString('restaurant_id', userId);
                          await prefs.setString('userEmail', _emailTextController.text);
                          await prefs.setString('restaurant_name', _restaurantNameTextController.text);

                          Navigator.pop(context); // Close the loading dialog
                          _showErrorSnackbar(context, "Account Created Successfully!");
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => RestaurantHomeScreen(restaurantId: userId,restaurantName:  _restaurantNameTextController.text,),
                            ),
                                (Route<dynamic> route) => false,
                          );
                        }).catchError((error) {
                          Navigator.pop(context); // Close the loading dialog
                          _showErrorSnackbar(context, "Error saving user data: ${error.toString()}");
                        });
                      } else {
                        Navigator.pop(context); // Close the loading dialog
                        showErrorSnackbar(context, "Account Already Exists!");
                      }
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:crypto/crypto.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import '../views/reusable_widgets.dart';
//
// class RestaurantSignUpScreen extends StatefulWidget {
//   const RestaurantSignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _RestaurantSignUpScreenState createState() => _RestaurantSignUpScreenState();
// }
//
// class _RestaurantSignUpScreenState extends State<RestaurantSignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordTextController = TextEditingController();
//   final TextEditingController _confirmPasswordTextController = TextEditingController();
//   final TextEditingController _emailTextController = TextEditingController();
//   final TextEditingController _userNameTextController = TextEditingController();
//   final TextEditingController _locationTextController = TextEditingController();
//   final TextEditingController _restaurantNameTextController = TextEditingController();
//
//   String _hashPassword(String password) {
//     final bytes = utf8.encode(password); // Convert the password to bytes
//     final digest = sha256.convert(bytes); // Hash the bytes using SHA-256
//     return digest.toString(); // Return the hash as a string
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Restaurant Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//         width: MediaQuery.of(context).size.width,
//         height: MediaQuery.of(context).size.height,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: <Widget>[
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter UserName",
//                     Icons.person_outline,
//                     false,
//                     _userNameTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a username';
//                       } else if (value.length < 3) {
//                         return 'Username must be at least 3 characters long';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Email Id",
//                     Icons.email_outlined,
//                     false,
//                     _emailTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter an email';
//                       } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Password",
//                     Icons.lock_outlined,
//                     true,
//                     _passwordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a password';
//                       } else if (value.length < 5) {
//                         return 'Password must be at least 5 characters long';
//                       } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
//                         return 'Password must include uppercase, lowercase, and special characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Confirm Password",
//                     Icons.lock_outlined,
//                     true,
//                     _confirmPasswordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       } else if (value != _passwordTextController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Location",
//                     Icons.location_on_outlined,
//                     false,
//                     _locationTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your location';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Restaurant Name",
//                     Icons.restaurant_menu,
//                     false,
//                     _restaurantNameTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter the restaurant name';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   signInSignUputton(context, false, () async {
//                     if (_formKey.currentState!.validate()) {
//                       showDialog(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (BuildContext context) {
//                           return Dialog(
//                             child: Padding(
//                               padding: const EdgeInsets.all(20.0),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircularProgressIndicator(),
//                                   SizedBox(width: 20),
//                                   Text("Creating account..."),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//
//                       // Hash the password
//                       String hashedPassword = _hashPassword(_passwordTextController.text);
//
//                       // Store restaurant information in Realtime Database
//
//                       DatabaseReference ref = FirebaseDatabase.instance.ref("restaurant_users");
//                       DatabaseEvent event = await ref.orderByChild("email").equalTo(_emailTextController.text).once();
//                       DataSnapshot snapshot = event.snapshot;
//
//                       DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("restaurant_users");
//                       String userId = usersRef.push().key!;
//
//                       if (!snapshot.exists) {
//                         usersRef.child(userId).set({
//                           "username": _userNameTextController.text,
//                           "email": _emailTextController.text,
//                           "password": hashedPassword,
//                           "location": _locationTextController.text,
//                           "restaurant_name": _restaurantNameTextController.text,
//                         }).then((_) {
//                           Navigator.pop(context); // Close the loading dialog
//                           print("Account Created Successfully!");
//                           Navigator.of(context).pushAndRemoveUntil(
//                             MaterialPageRoute(
//                               builder: (context) => HomeScreen(),
//                             ),
//                                 (Route<dynamic> route) => false,
//                           );
//                         }).catchError((error) {
//                           Navigator.pop(context); // Close the loading dialog
//                           print("Error saving user data: ${error.toString()}");
//                         });
//                       }else{
//                         Navigator.of(context).pop();
//                         //showErrorDialog(context, "Account Already Exsist!");
//                         showErrorSnackbar(context, "Account Already Exsist!");
//                         // Close the loading dialog
//
//                       }
//
//
//
//
//
//
//                     }
//                   }),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//
//     );
//
//   }
//
//
// }
//





// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class RestaurantSignUpScreen extends StatefulWidget {
//   const RestaurantSignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _RestaurantSignUpScreenState createState() => _RestaurantSignUpScreenState();
// }
//
// class _RestaurantSignUpScreenState extends State<RestaurantSignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordTextController = TextEditingController();
//   final TextEditingController _confirmPasswordTextController = TextEditingController();
//   final TextEditingController _emailTextController = TextEditingController();
//   final TextEditingController _userNameTextController = TextEditingController();
//   final TextEditingController _locationTextController = TextEditingController();
//   final TextEditingController _restaurantNameTextController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Restaurant Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//         width: MediaQuery.of(context).size.width,
//         height: MediaQuery.of(context).size.height,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: <Widget>[
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter UserName",
//                     Icons.person_outline,
//                     false,
//                     _userNameTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a username';
//                       } else if (value.length < 3) {
//                         return 'Username must be at least  characters long';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Email Id",
//                     Icons.person_outline,
//                     false,
//                     _emailTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter an email';
//                       } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Password",
//                     Icons.lock_outlined,
//                     true,
//                     _passwordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a password';
//                       } else if (value.length < 5) {
//                         return 'Password must be at least 5 characters long';
//                       } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
//                         return 'Password must include uppercase, lowercase, and special characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Confirm Password",
//                     Icons.lock_outlined,
//                     true,
//                     _confirmPasswordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       } else if (value != _passwordTextController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Location",
//                     Icons.location_on_outlined,
//                     false,
//                     _locationTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your location';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Restaurant Name",
//                     Icons.restaurant,
//                     false,
//                     _restaurantNameTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter your restaurant name';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   signInSignUputton(context, false, () {
//                     if (_formKey.currentState!.validate()) {
//                       showDialog(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (BuildContext context) {
//                           return Dialog(
//                             child: Padding(
//                               padding: const EdgeInsets.all(20.0),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircularProgressIndicator(),
//                                   SizedBox(width: 20),
//                                   Text("Creating account..."),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//
//                       // Store user information in Realtime Database
//                       DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("restaurant_users");
//                       String userId = usersRef.push().key!;
//                       usersRef.child(userId).set({
//                         "username": _userNameTextController.text,
//                         "email": _emailTextController.text,
//                         "password": _passwordTextController.text,
//                         "location": _locationTextController.text,
//                         "restaurant_name": _restaurantNameTextController.text,
//                       }).then((_) {
//                         Navigator.pop(context); // Close the loading dialog
//                         print("Account Created Successfully!");
//                         Navigator.of(context).pushAndRemoveUntil(
//                           MaterialPageRoute(
//                             builder: (context) => HomeScreen(),
//                           ),
//                               (Route<dynamic> route) => false,
//                         );
//                       }).catchError((error) {
//                         Navigator.pop(context); // Close the loading dialog
//                         print("Error saving user data: ${error.toString()}");
//                       });
//                     }
//                   }),
//                 ],
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
















// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordTextController = TextEditingController();
//   final TextEditingController _confirmPasswordTextController = TextEditingController();
//   final TextEditingController _emailTextController = TextEditingController();
//   final TextEditingController _userNameTextController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//         width: MediaQuery.of(context).size.width,
//         height: MediaQuery.of(context).size.height,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: <Widget>[
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter UserName",
//                     Icons.person_outline,
//                     false,
//                     _userNameTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a username';
//                       } else if (value.length < 3) {
//                         return 'Username must be at least 3 characters long';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Email Id",
//                     Icons.person_outline,
//                     false,
//                     _emailTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter an email';
//                       } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Password",
//                     Icons.lock_outlined,
//                     true,
//                     _passwordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a password';
//                       } else if (value.length < 5) {
//                         return 'Password must be at least 5 characters long';
//                       } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
//                         return 'Password must include uppercase, lowercase, and special characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Confirm Password",
//                     Icons.lock_outlined,
//                     true,
//                     _confirmPasswordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       } else if (value != _passwordTextController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   signInSignUputton(context, false, () {
//                     if (_formKey.currentState!.validate()) {
//                       showDialog(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (BuildContext context) {
//                           return Dialog(
//                             child: Padding(
//                               padding: const EdgeInsets.all(20.0),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircularProgressIndicator(),
//                                   SizedBox(width: 20),
//                                   Text("Creating account..."),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//
//                       FirebaseAuth.instance
//                           .createUserWithEmailAndPassword(
//                           email: _emailTextController.text,
//                           password: _passwordTextController.text)
//                           .then((value) {
//                         Navigator.pop(context); // Close the loading dialog
//                         print("Account Created Successfully!");
//                         Navigator.of(context).pushAndRemoveUntil(
//                             MaterialPageRoute(
//                                 builder: (context) => HomeScreen()),
//                                 (Route<dynamic> route) => false);
//                       }).catchError((error) {
//                         Navigator.pop(context); // Close the loading dialog
//                         print("Error ${error.toString()}");
//                       });
//                     }
//                   }),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//










// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _passwordTextController = TextEditingController();
//   TextEditingController _confirmPasswordTextController = TextEditingController();
//   TextEditingController _emailTextController = TextEditingController();
//   TextEditingController _userNameTextController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//         width: MediaQuery.of(context).size.width,
//         height: MediaQuery.of(context).size.height,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: <Widget>[
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter UserName",
//                     Icons.person_outline,
//                     false,
//                     _userNameTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a username';
//                       } else if (value.length < 3) {
//                         return 'Username must be at least 3 characters long';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Email Id",
//                     Icons.person_outline,
//                     false,
//                     _emailTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter an email';
//                       } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                         return 'Please enter a valid email';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Enter Password",
//                     Icons.lock_outlined,
//                     true,
//                     _passwordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please enter a password';
//                       } else if (value.length < 5) {
//                         return 'Password must be at least 5 characters long';
//                       } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
//                         return 'Password must include uppercase, lowercase, and special characters';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   reusableTextField(
//                     "Confirm Password",
//                     Icons.lock_outlined,
//                     true,
//                     _confirmPasswordTextController,
//                         (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Please confirm your password';
//                       } else if (value != _passwordTextController.text) {
//                         return 'Passwords do not match';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//                   signInSignUputton(context, false, () {
//                     if (_formKey.currentState!.validate()) {
//                       showDialog(
//                         context: context,
//                         barrierDismissible: false,
//                         builder: (BuildContext context) {
//                           return Dialog(
//                             child: Padding(
//                               padding: const EdgeInsets.all(20.0),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   CircularProgressIndicator(),
//                                   SizedBox(width: 20),
//                                   Text("Creating account..."),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//
//                       FirebaseAuth.instance
//                           .createUserWithEmailAndPassword(
//                           email: _emailTextController.text,
//                           password: _passwordTextController.text)
//                           .then((value) {
//                         Navigator.pop(context); // Close the loading dialog
//                         print("Account Created Successfully!");
//                         Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                                 builder: (context) => HomeScreen())).onError(
//                                 (error, stackTrace) {
//                               print("Error ${error.toString()}");
//                             });
//                       }).catchError((error) {
//                         Navigator.pop(context); // Close the loading dialog
//                         print("Error ${error.toString()}");
//                       });
//                     }
//                   }),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//
// }








// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _passwordTextController = TextEditingController();
//   TextEditingController _emailTextController = TextEditingController();
//   TextEditingController _userNameTextController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           decoration: BoxDecoration(
//               gradient: LinearGradient(
//                   colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter)),
//           child: SingleChildScrollView(
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: <Widget>[
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       reusableTextField(
//                         "Enter UserName",
//                         Icons.person_outline,
//                         false,
//                         _userNameTextController,
//                             (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a username';
//                           } else if (value.length < 3) {
//                             return 'Username must be at least 3 characters long';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       reusableTextField(
//                         "Enter Email Id",
//                         Icons.person_outline,
//                         false,
//                         _emailTextController,
//                             (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter an email';
//                           } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       reusableTextField(
//                         "Enter Password",
//                         Icons.lock_outlined,
//                         true,
//                         _passwordTextController,
//                             (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a password';
//                           } else if (value.length < 5) {
//                             return 'Password must be at least 5 characters long';
//                           } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
//                             return 'Password must include uppercase, lowercase, and special characters';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       signInSignUputton(context, false, () {
//                         if (_formKey.currentState!.validate()) {
//                           showDialog(
//                             context: context,
//                             barrierDismissible: false,
//                             builder: (BuildContext context) {
//                               return Dialog(
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(20.0),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       CircularProgressIndicator(),
//                                       SizedBox(width: 20),
//                                       Text("Creating account..."),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           );
//
//                           FirebaseAuth.instance
//                               .createUserWithEmailAndPassword(
//                               email: _emailTextController.text,
//                               password: _passwordTextController.text)
//                               .then((value) {
//                             Navigator.pop(context); // Close the loading dialog
//                             print("Account Created Successfully!");
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => HomeScreen())).onError(
//                                     (error, stackTrace) {
//                                   print("Error ${error.toString()}");
//                                 });
//                           }).catchError((error) {
//                             Navigator.pop(context); // Close the loading dialog
//                             print("Error ${error.toString()}");
//                           });
//                         }
//                       }),
//                     ],
//                   ),
//                 ),
//               ))),
//     );
//   }
//
//   Widget reusableTextField(String hintText, IconData icon, bool isPasswordType,
//       TextEditingController controller, String? Function(String?)? validator) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPasswordType,
//       validator: validator,
//       cursorColor: Colors.white,
//       style: TextStyle(color: Colors.black.withOpacity(0.9)),
//       decoration: InputDecoration(
//         prefixIcon: Icon(
//           icon,
//           color: Colors.black,
//         ),
//         labelText: hintText,
//         labelStyle: TextStyle(color: Colors.black.withOpacity(0.9)),
//         filled: true,
//         floatingLabelBehavior: FloatingLabelBehavior.never,
//         fillColor: Colors.white.withOpacity(0.3),
//         border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30.0),
//             borderSide: const BorderSide(width: 0, style: BorderStyle.none)),
//       ),
//       keyboardType: isPasswordType
//           ? TextInputType.visiblePassword
//           : TextInputType.emailAddress,
//     );
//   }
// }





// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _passwordTextController = TextEditingController();
//   TextEditingController _emailTextController = TextEditingController();
//   TextEditingController _userNameTextController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           decoration: BoxDecoration(
//               gradient: LinearGradient(
//                   colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter)),
//           child: SingleChildScrollView(
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     children: <Widget>[
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       reusableTextField(
//                         "Enter UserName",
//                         Icons.person_outline,
//                         false,
//                         _userNameTextController,
//                             (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a username';
//                           } else if (value.length < 3) {
//                             return 'Username must be at least 3 characters long';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       reusableTextField(
//                         "Enter Email Id",
//                         Icons.person_outline,
//                         false,
//                         _emailTextController,
//                             (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter an email';
//                           } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                             return 'Please enter a valid email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       reusableTextField(
//                         "Enter Password",
//                         Icons.lock_outlined,
//                         true,
//                         _passwordTextController,
//                             (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a password';
//                           } else if (value.length < 5) {
//                             return 'Password must be at least 5 characters long';
//                           } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W)').hasMatch(value)) {
//                             return 'Password must include uppercase, lowercase, and special characters';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(
//                         height: 20,
//                       ),
//                       signInSignUputton(context, false, () {
//                         if (_formKey.currentState!.validate()) {
//                           FirebaseAuth.instance
//                               .createUserWithEmailAndPassword(
//                               email: _emailTextController.text,
//                               password: _passwordTextController.text)
//                               .then((value) {
//                             print("Account Created Successfully!");
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => HomeScreen())).onError(
//                                     (error, stackTrace) {
//                                   print("Error ${error.toString()}");
//                                 });
//                           });
//                         }
//                       }),
//                     ],
//                   ),
//                 ),
//               ))),
//     );
//   }
//
//   Widget reusableTextField(String hintText, IconData icon, bool isPasswordType,
//       TextEditingController controller, String? Function(String?)? validator) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPasswordType,
//       validator: validator,
//       cursorColor: Colors.white,
//       style: TextStyle(color: Colors.black.withOpacity(0.9)),
//       decoration: InputDecoration(
//         prefixIcon: Icon(
//           icon,
//           color: Colors.black,
//         ),
//         labelText: hintText,
//         labelStyle: TextStyle(color: Colors.black.withOpacity(0.9)),
//         filled: true,
//         floatingLabelBehavior: FloatingLabelBehavior.never,
//         fillColor: Colors.white.withOpacity(0.3),
//         border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30.0),
//             borderSide: const BorderSide(width: 0, style: BorderStyle.none)),
//       ),
//       keyboardType: isPasswordType
//           ? TextInputType.visiblePassword
//           : TextInputType.emailAddress,
//     );
//   }
// }
//
//











// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({Key? key}) : super(key: key);
//
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   TextEditingController _passwordTextController = TextEditingController();
//   TextEditingController _emailTextController = TextEditingController();
//   TextEditingController _userNameTextController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Sign Up",
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//       body: Container(
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           decoration: BoxDecoration(
//               gradient: LinearGradient(colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
//                   begin: Alignment.topCenter, end: Alignment.bottomCenter)),
//           child: SingleChildScrollView(
//               child: Padding(
//                 padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
//                 child: Column(
//                   children: <Widget>[
//                     const SizedBox(
//                       height: 20,
//                     ),
//                     reusableTextField("Enter UserName", Icons.person_outline, false,
//                         _userNameTextController),
//                     const SizedBox(
//                       height: 20,
//                     ),
//                     reusableTextField("Enter Email Id", Icons.person_outline, false,
//                         _emailTextController),
//                     const SizedBox(
//                       height: 20,
//                     ),
//                     reusableTextField("Enter Password", Icons.lock_outlined, true,
//                         _passwordTextController),
//                     const SizedBox(
//                       height: 20,
//                     ),
//                     signInSignUputton(context, false, (){
//                       FirebaseAuth.instance
//                           .createUserWithEmailAndPassword(
//                           email: _emailTextController.text,
//                           password: _passwordTextController.text)
//                           .then( (value) {
//                             print("Account Created Successfully!");
//                             Navigator.push(context,
//                             MaterialPageRoute(builder: (context) => HomeScreen())
//                             ).onError(
//                                 (error , stackTrace) {
//                                   print("Error ${error.toString()}");
//                                 }
//                             );
//                       });
//                     })
//                   ],
//                 ),
//               ))),
//     );
//   }
// }