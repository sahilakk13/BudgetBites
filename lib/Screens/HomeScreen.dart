import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'RoleSelectionScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});


  bool loading = false;
  final TextEditingController _textController = TextEditingController();
  final databaseRef = FirebaseDatabase.instance.ref('post');



  @override
  Widget build(BuildContext context) {

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
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        backgroundColor: Color(0xFFFF9A8B),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Enter something",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle the submit action
                databaseRef.child(DateTime.now().millisecondsSinceEpoch.toString()).set({
                  'title' : _textController.text.toString(),
                  'id' : DateTime.now().millisecondsSinceEpoch.toString()
                });
                print("Submitted: ${_textController.text}");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF9A8B),
              ),
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

}



// import 'package:flutter/material.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Container(
//         child: Text("Hello"),
//       ),
//     );
//   }
// }
