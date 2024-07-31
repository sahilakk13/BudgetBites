// import 'package:bb/Screens/CustomerSignUpScreen.dart';
// import 'package:bb/Screens/RestaurantSignUpScreen.dart';
// import 'package:bb/Screens/HomeScreen.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../views/reusable_widgets.dart';
//
// class SignInScreen extends StatefulWidget {
//   const SignInScreen({super.key});
//
//   @override
//   State<SignInScreen> createState() => _SignInScreenState();
// }
//
// class _SignInScreenState extends State<SignInScreen> {
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
//               padding: EdgeInsets.only(left: 20, right: 20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: <Widget>[
//                     logoWidget('assets/logot.png'),
//                     SizedBox(
//                       height: 30,
//                     ),
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
//                     SizedBox(
//                       height: 20,
//                     ),
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
//                     SizedBox(
//                       height: 20,
//                     ),
//                     if (errorMessage != null)
//                       Text(
//                         errorMessage!,
//                         style: TextStyle(color: Colors.red),
//                       ),
//                     SizedBox(
//                       height: 20,
//                     ),
//                     signInSignUputton(context, true, () {
//                       if (_formKey.currentState!.validate()) {
//                         setState(() {
//                           errorMessage = null;
//                         });
//                         showDialog(
//                           context: context,
//                           barrierDismissible: false,
//                           builder: (BuildContext context) {
//                             return Dialog(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(20.0),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     CircularProgressIndicator(),
//                                     SizedBox(width: 20),
//                                     Text("Signing in..."),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         );
//
//                         FirebaseAuth.instance
//                             .signInWithEmailAndPassword(
//                           email: _emailTextController.text,
//                           password: _passwordTextController.text,
//                         )
//                             .then((value) {
//                           Navigator.pop(context); // Close the loading dialog
//                           print("Signed in Successfully!");
//                           Navigator.of(context).pushAndRemoveUntil(
//                               MaterialPageRoute(builder: (context) => HomeScreen()),
//                                   (Route<dynamic> route) => false);
//                         }).catchError((error) {
//                           Navigator.pop(context); // Close the loading dialog
//                           setState(() {
//                             errorMessage = getErrorMessage(error.code);
//                           });
//                           print("Error ${error.toString()}");
//                         });
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
//   String getErrorMessage(String errorCode) {
//     switch (errorCode) {
//       case 'invalid-email':
//         return 'The email address is badly formatted.';
//       case 'user-not-found':
//         return 'No user found for that email.';
//       case 'wrong-password':
//         return 'Wrong password provided.';
//       case 'invalid-credential':
//         return 'The supplied auth credential is incorrect, malformed or has expired.';
//       default:
//         return 'An error occurred. Please try again.';
//     }
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
//                 MaterialPageRoute(builder: (context) => CustomerSignUpScreen()));
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
//
//
//
//
//
//
//
// // import 'package:bb/Screens/RestaurantSignUpScreen.dart';
// // import 'package:bb/Screens/HomeScreen.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import '../views/reusable_widgets.dart';
// //
// // class SignInScreen extends StatefulWidget {
// //   const SignInScreen({super.key});
// //
// //   @override
// //   State<SignInScreen> createState() => _SignInScreenState();
// // }
// //
// // class _SignInScreenState extends State<SignInScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   TextEditingController _passwordTextController = TextEditingController();
// //   TextEditingController _emailTextController = TextEditingController();
// //   String? errorMessage;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //           ),
// //         ),
// //         child: Center(
// //           child: SingleChildScrollView(
// //             child: Padding(
// //               padding: EdgeInsets.only(left: 20, right: 20),
// //               child: Form(
// //                 key: _formKey,
// //                 child: Column(
// //                   children: <Widget>[
// //                     logoWidget('assets/logot.png'),
// //                     SizedBox(
// //                       height: 30,
// //                     ),
// //                     reusableTextField(
// //                       "Enter Email",
// //                       Icons.person_outline,
// //                       false,
// //                       _emailTextController,
// //                           (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'Please enter an email';
// //                         } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
// //                           return 'Please enter a valid email';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     reusableTextField(
// //                       "Enter Password",
// //                       Icons.lock_outline,
// //                       true,
// //                       _passwordTextController,
// //                           (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'Please enter a password';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     if (errorMessage != null)
// //                       Text(
// //                         errorMessage!,
// //                         style: TextStyle(color: Colors.red),
// //                       ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     signInSignUputton(context, true, () {
// //                       if (_formKey.currentState!.validate()) {
// //                         setState(() {
// //                           errorMessage = null;
// //                         });
// //                         showDialog(
// //                           context: context,
// //                           barrierDismissible: false,
// //                           builder: (BuildContext context) {
// //                             return Dialog(
// //                               child: Padding(
// //                                 padding: const EdgeInsets.all(20.0),
// //                                 child: Row(
// //                                   mainAxisSize: MainAxisSize.min,
// //                                   children: [
// //                                     CircularProgressIndicator(),
// //                                     SizedBox(width: 20),
// //                                     Text("Signing in..."),
// //                                   ],
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         );
// //
// //                         FirebaseAuth.instance
// //                             .signInWithEmailAndPassword(
// //                           email: _emailTextController.text,
// //                           password: _passwordTextController.text,
// //                         )
// //                             .then((value) {
// //                           Navigator.pop(context); // Close the loading dialog
// //                           print("Signed in Successfully!");
// //                           Navigator.push(context,
// //                               MaterialPageRoute(builder: (context) => HomeScreen()));
// //                         }).catchError((error) {
// //                           Navigator.pop(context); // Close the loading dialog
// //                           setState(() {
// //                             errorMessage = getErrorMessage(error.code);
// //                           });
// //                           print("Error ${error.toString()}");
// //                         });
// //                       }
// //                     }),
// //                     signUpOption(),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   String getErrorMessage(String errorCode) {
// //     switch (errorCode) {
// //       case 'invalid-email':
// //         return 'The email address is badly formatted.';
// //       case 'user-not-found':
// //         return 'No user found for that email.';
// //       case 'wrong-password':
// //         return 'Wrong password provided.';
// //       case 'invalid-credential':
// //         return 'The supplied auth credential is incorrect, malformed or has expired.';
// //       default:
// //         return 'An error occurred. Please try again.';
// //     }
// //   }
// //
// //   Image logoWidget(String imageName) {
// //     return Image.asset(
// //       imageName,
// //       fit: BoxFit.contain,
// //       width: 240,
// //       height: 240,
// //     );
// //   }
// //
// //   Row signUpOption() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         const Text("Don't have an account?",
// //             style: TextStyle(color: Colors.black)),
// //         GestureDetector(
// //           onTap: () {
// //             Navigator.push(context,
// //                 MaterialPageRoute(builder: (context) => SignUpScreen()));
// //           },
// //           child: const Text(
// //             " Sign Up",
// //             style: TextStyle(
// //                 color: Colors.black, fontWeight: FontWeight.bold),
// //           ),
// //         )
// //       ],
// //     );
// //   }
// //
// //
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:bb/Screens/RestaurantSignUpScreen.dart';
// // import 'package:bb/Screens/HomeScreen.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import '../views/reusable_widgets.dart';
// //
// // class SignInScreen extends StatefulWidget {
// //   const SignInScreen({super.key});
// //
// //   @override
// //   State<SignInScreen> createState() => _SignInScreenState();
// // }
// //
// // class _SignInScreenState extends State<SignInScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   TextEditingController _passwordTextController = TextEditingController();
// //   TextEditingController _emailTextController = TextEditingController();
// //   String? errorMessage;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //           ),
// //         ),
// //         child: Center(
// //           child: SingleChildScrollView(
// //             child: Padding(
// //               padding: EdgeInsets.only(left: 20, right: 20),
// //               child: Form(
// //                 key: _formKey,
// //                 child: Column(
// //                   children: <Widget>[
// //                     logoWidget('assets/logot.png'),
// //                     SizedBox(
// //                       height: 30,
// //                     ),
// //                     reusableTextField(
// //                       "Enter Email",
// //                       Icons.person_outline,
// //                       false,
// //                       _emailTextController,
// //                           (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'Please enter an email';
// //                         } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
// //                           return 'Please enter a valid email';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     reusableTextField(
// //                       "Enter Password",
// //                       Icons.lock_outline,
// //                       true,
// //                       _passwordTextController,
// //                           (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'Please enter a password';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     if (errorMessage != null)
// //                       Text(
// //                         errorMessage!,
// //                         style: TextStyle(color: Colors.red),
// //                       ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     signInSignUputton(context, true, () {
// //                       if (_formKey.currentState!.validate()) {
// //                         setState(() {
// //                           errorMessage = null;
// //                         });
// //                         showDialog(
// //                           context: context,
// //                           barrierDismissible: false,
// //                           builder: (BuildContext context) {
// //                             return Dialog(
// //                               child: Padding(
// //                                 padding: const EdgeInsets.all(20.0),
// //                                 child: Row(
// //                                   mainAxisSize: MainAxisSize.min,
// //                                   children: [
// //                                     CircularProgressIndicator(),
// //                                     SizedBox(width: 20),
// //                                     Text("Signing in..."),
// //                                   ],
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         );
// //
// //                         FirebaseAuth.instance
// //                             .signInWithEmailAndPassword(
// //                           email: _emailTextController.text,
// //                           password: _passwordTextController.text,
// //                         )
// //                             .then((value) {
// //                           Navigator.pop(context); // Close the loading dialog
// //                           print("Signed in Successfully!");
// //                           Navigator.push(context,
// //                               MaterialPageRoute(builder: (context) => HomeScreen()));
// //                         }).catchError((error) {
// //                           Navigator.pop(context); // Close the loading dialog
// //                           setState(() {
// //                             errorMessage = getErrorMessage(error.code);
// //                           });
// //                           print("Error ${error.toString()}");
// //                         });
// //                       }
// //                     }),
// //                     signUpOption(),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   String getErrorMessage(String errorCode) {
// //     switch (errorCode) {
// //       case 'invalid-email':
// //         return 'The email address is badly formatted.';
// //       case 'user-not-found':
// //         return 'No user found for that email.';
// //       case 'wrong-password':
// //         return 'Wrong password provided.';
// //       default:
// //         return 'An error occurred. Please try again.';
// //     }
// //   }
// //
// //   Image logoWidget(String imageName) {
// //     return Image.asset(
// //       imageName,
// //       fit: BoxFit.contain,
// //       width: 240,
// //       height: 240,
// //     );
// //   }
// //
// //   Row signUpOption() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         const Text("Don't have an account?",
// //             style: TextStyle(color: Colors.black)),
// //         GestureDetector(
// //           onTap: () {
// //             Navigator.push(context,
// //                 MaterialPageRoute(builder: (context) => SignUpScreen()));
// //           },
// //           child: const Text(
// //             " Sign Up",
// //             style: TextStyle(
// //                 color: Colors.black, fontWeight: FontWeight.bold),
// //           ),
// //         )
// //       ],
// //     );
// //   }
// //
// // }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// // import 'package:bb/Screens/RestaurantSignUpScreen.dart';
// // import 'package:bb/Screens/HomeScreen.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import '../views/reusable_widgets.dart';
// //
// // class SignInScreen extends StatefulWidget {
// //   const SignInScreen({super.key});
// //
// //   @override
// //   State<SignInScreen> createState() => _SignInScreenState();
// // }
// //
// // class _SignInScreenState extends State<SignInScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   TextEditingController _passwordTextController = TextEditingController();
// //   TextEditingController _emailTextController = TextEditingController();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //           ),
// //         ),
// //         child: Center(
// //           child: SingleChildScrollView(
// //             child: Padding(
// //               padding: EdgeInsets.only(left: 20, right: 20),
// //               child: Form(
// //                 key: _formKey,
// //                 child: Column(
// //                   children: <Widget>[
// //                     logoWidget('assets/logot.png'),
// //                     SizedBox(
// //                       height: 30,
// //                     ),
// //                     reusableTextField(
// //                       "Enter Email",
// //                       Icons.person_outline,
// //                       false,
// //                       _emailTextController,
// //                           (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'Please enter an email';
// //                         } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
// //                           return 'Please enter a valid email';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     reusableTextField(
// //                       "Enter Password",
// //                       Icons.lock_outline,
// //                       true,
// //                       _passwordTextController,
// //                           (value) {
// //                         if (value == null || value.isEmpty) {
// //                           return 'Please enter a password';
// //                         }
// //                         return null;
// //                       },
// //                     ),
// //                     SizedBox(
// //                       height: 20,
// //                     ),
// //                     signInSignUputton(context, true, () {
// //                       if (_formKey.currentState!.validate()) {
// //                         showDialog(
// //                           context: context,
// //                           barrierDismissible: false,
// //                           builder: (BuildContext context) {
// //                             return Dialog(
// //                               child: Padding(
// //                                 padding: const EdgeInsets.all(20.0),
// //                                 child: Row(
// //                                   mainAxisSize: MainAxisSize.min,
// //                                   children: [
// //                                     CircularProgressIndicator(),
// //                                     SizedBox(width: 20),
// //                                     Text("Signing in..."),
// //                                   ],
// //                                 ),
// //                               ),
// //                             );
// //                           },
// //                         );
// //
// //                         FirebaseAuth.instance
// //                             .signInWithEmailAndPassword(
// //                           email: _emailTextController.text,
// //                           password: _passwordTextController.text,
// //                         )
// //                             .then((value) {
// //                           Navigator.pop(context); // Close the loading dialog
// //                           print("Signed in Successfully!");
// //                           Navigator.push(context,
// //                               MaterialPageRoute(builder: (context) => HomeScreen()));
// //                         }).catchError((error) {
// //                           Navigator.pop(context); // Close the loading dialog
// //                           print("Error ${error.toString()}");
// //                         });
// //                       }
// //                     }),
// //                     signUpOption(),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Image logoWidget(String imageName) {
// //     return Image.asset(
// //       imageName,
// //       fit: BoxFit.contain,
// //       width: 240,
// //       height: 240,
// //     );
// //   }
// //
// //   Row signUpOption() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         const Text("Don't have an account?",
// //             style: TextStyle(color: Colors.black)),
// //         GestureDetector(
// //           onTap: () {
// //             Navigator.push(context,
// //                 MaterialPageRoute(builder: (context) => SignUpScreen()));
// //           },
// //           child: const Text(
// //             " Sign Up",
// //             style: TextStyle(
// //                 color: Colors.black, fontWeight: FontWeight.bold),
// //           ),
// //         )
// //       ],
// //     );
// //   }
// //
// //   // Widget reusableTextField(String hintText, IconData icon, bool isPasswordType,
// //   //     TextEditingController controller, String? Function(String?)? validator) {
// //   //   return TextFormField(
// //   //     controller: controller,
// //   //     obscureText: isPasswordType,
// //   //     validator: validator,
// //   //     cursorColor: Colors.white,
// //   //     style: TextStyle(color: Colors.black.withOpacity(0.9)),
// //   //     decoration: InputDecoration(
// //   //       prefixIcon: Icon(
// //   //         icon,
// //   //         color: Colors.black,
// //   //       ),
// //   //       labelText: hintText,
// //   //       labelStyle: TextStyle(color: Colors.black.withOpacity(0.9)),
// //   //       filled: true,
// //   //       floatingLabelBehavior: FloatingLabelBehavior.never,
// //   //       fillColor: Colors.white.withOpacity(0.3),
// //   //       border: OutlineInputBorder(
// //   //         borderRadius: BorderRadius.circular(30.0),
// //   //         borderSide: const BorderSide(width: 0, style: BorderStyle.none),
// //   //       ),
// //   //     ),
// //   //     keyboardType: isPasswordType
// //   //         ? TextInputType.visiblePassword
// //   //         : TextInputType.emailAddress,
// //   //   );
// //   // }
// // }
// //
//
//
//
//
//
//
// // import 'package:bb/Screens/RestaurantSignUpScreen.dart';
// // import 'package:bb/Screens/HomeScreen.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import '../views/reusable_widgets.dart';
// //
// // class SignInScreen extends StatefulWidget {
// //   const SignInScreen({super.key});
// //
// //   @override
// //   State<SignInScreen> createState() => _SignInScreenState();
// // }
// //
// // class _SignInScreenState extends State<SignInScreen> {
// //
// //   TextEditingController _passwordTextController=TextEditingController();
// //   TextEditingController _emailTextController=TextEditingController();
// //
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: BoxDecoration(
// //           gradient: LinearGradient(
// //             colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
// //             begin: Alignment.topLeft,
// //             end: Alignment.bottomRight,
// //           ),
// //         ),
// //         child: Center(
// //           child: SingleChildScrollView(
// //             child:Padding(
// //               padding:  //EdgeInsets.fromLTRB(20, MediaQuery.of(context).size.height*0.010, 20, 0),
// //               EdgeInsets.only(left: 20,right: 20),
// //               child: Column(
// //                 children: <Widget>[
// //                 logoWidget('assets/logot.png'),
// //                 SizedBox(
// //                   height: 30,
// //                 ),
// //                 reusableTextField("Enter Username", Icons.person_outline, false, _emailTextController),
// //                 SizedBox(
// //                   height: 20,
// //                 ),
// //                 reusableTextField("Enter Password", Icons.lock_outline, true, _passwordTextController),
// //                   SizedBox(
// //                     height: 20,
// //                   ),
// //                   signInSignUputton(context, true, (){
// //                     FirebaseAuth.instance.signInWithEmailAndPassword(
// //                         email: _emailTextController.text,
// //                         password:_passwordTextController.text ).then((value){
// //                       print("Account Created Successfully!");
// //                       Navigator.push(context,
// //                           MaterialPageRoute(builder: (context) => HomeScreen())
// //                       ).onError(
// //                               (error , stackTrace) {
// //                             print("Error ${error.toString()}");
// //                           }
// //                       );
// //                     });
// //                   }),
// //                   signUpOption()
// //               ],
// //                         ),
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Image logoWidget(String imageName) {
// //     return Image.asset(
// //       imageName,
// //       fit: BoxFit.contain,
// //       width: 240,
// //       height: 240,
// //     );
// //   }
// //
// //
// //   Row signUpOption() {
// //     return Row(
// //       mainAxisAlignment: MainAxisAlignment.center,
// //       children: [
// //         const Text ("Don't have account?",
// //             style: TextStyle(color: Colors.black)),
// //         GestureDetector(onTap: () {
// //           Navigator.push(context,
// //               MaterialPageRoute(builder: (context) => SignUpScreen()));
// //         },
// //
// //           child:
// //           const Text(
// //             " Sign Up",
// //             style: TextStyle(
// //                 color: Colors.black, fontWeight: FontWeight.bold),
// //           ),
// //         )
// //       ],
// //
// //     );
// //   }
// // }
// //
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// //
// // class SignInScreen extends StatefulWidget {
// //   const SignInScreen({super.key});
// //
// //   @override
// //   State<SignInScreen> createState() => _SignInScreenState();
// // }
// //
// // class _SignInScreenState extends State<SignInScreen> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                 colors: [Color(0xFFFFF1C1), Color(0xFFFF9A8B)],
// //                 begin: Alignment.topLeft,
// //                 end: Alignment.bottomRight,
// //               ),
// //
// //         ),
// //         child: SingleChildScrollView(
// //           child: Padding(
// //             padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).size.height*0.2, 20, 0),
// //             child: Column(
// //               children: <Widget>[
// //                 logoWidget('assets/logot.png')
// //
// //               ],
// //             ),
// //           ),
// //         ),
// //       ),
// //     );;
// //   }
// // }
// //
// //
// //
// //
// //
// // Image logoWidget (String imageName) {
// //   return Image.asset(
// //     imageName,
// //     fit: BoxFit.fitWidth,
// //     width: 240,
// //     height: 240,
// //     //color: Colors.white,
// //
// //   );
// // }
// //
// //
// //
// //
