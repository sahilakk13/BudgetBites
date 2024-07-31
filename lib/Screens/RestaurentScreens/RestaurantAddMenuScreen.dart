import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  AddMenuScreen({required this.restaurantId, required this.restaurantName});

  @override
  _AddMenuScreenState createState() => _AddMenuScreenState();
}

class _AddMenuScreenState extends State<AddMenuScreen> {
  late DatabaseReference databaseRef;
  late String restaurantName;
  final List<Map<String, dynamic>> _menuItems = [];
  final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];

  @override
  void initState() {
    super.initState();
    databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
    _fetchMenuItems();
    restaurantName = widget.restaurantName;
  }

  void _fetchMenuItems() async {
    databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final List<Map<String, dynamic>> menuItems = [];
        data.forEach((key, value) {
          final item = value as Map<dynamic, dynamic>;
          menuItems.add({
            'key': key,
            'name': item['name'] as String,
            'description': item['description'] as String,
            'pricePKR': item['pricePKR'] as String,
            'quantity': item['quantity'] as String,
            'type': item['type'] as String,
            'available': item['available'] ?? true,
            'imageUrl': item['imageUrl'] as String?,
          });
        });
        setState(() {
          _menuItems.clear();
          _menuItems.addAll(menuItems);
        });
      }
    });
  }

  Future<String?> _uploadImage(dynamic imageFile, String restaurantId, String menuItemId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('menu_images/$restaurantId/$menuItemId.jpg');
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(imageFile);
      } else {
        uploadTask = storageRef.putFile(imageFile);
      }
      final taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, dynamic imageFile) async {
    final newItemRef = databaseRef.push();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadImage(imageFile, widget.restaurantId, newItemRef.key!);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
        return;
      }
    }

    final newMenuItem = {
      'name': name,
      'description': description,
      'pricePKR': pricePKR,
      'quantity': quantity,
      'type': type,
      'available': true,
      'restaurant_name': restaurantName,
      'imageUrl': imageUrl,
    };

    newItemRef.set(newMenuItem);

    newMenuItem['key'] = newItemRef.key;
    setState(() {
      _menuItems.add(newMenuItem);
    });
  }

  void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, dynamic imageFile, String? oldImageUrl) async {
    String? imageUrl = oldImageUrl;
    if (imageFile != null) {
      if (oldImageUrl != null) {
        await _deleteImage(oldImageUrl);
      }
      imageUrl = await _uploadImage(imageFile, widget.restaurantId, key);
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
        return;
      }
    }

    final updatedMenuItem = {
      'name': name,
      'description': description,
      'pricePKR': pricePKR,
      'quantity': quantity,
      'type': type,
      'available': available,
      'imageUrl': imageUrl,
    };

    databaseRef.child(key).update(updatedMenuItem);

    setState(() {
      final index = _menuItems.indexWhere((item) => item['key'] == key);
      if (index != -1) {
        _menuItems[index] = updatedMenuItem;
        _menuItems[index]['key'] = key;
      }
    });
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  void _deleteMenuItem(String key, String? imageUrl) async {
    if (imageUrl != null) {
      await _deleteImage(imageUrl);
    }
    databaseRef.child(key).remove();
    setState(() {
      _menuItems.removeWhere((item) => item['key'] == key);
    });
  }

  void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
    final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
    final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
    final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
    final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
    String selectedType = currentItem?['type'] ?? _dishTypes.first;
    bool available = currentItem?['available'] ?? true;
    dynamic imageFile;
    String? imageUrl = currentItem?['imageUrl'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Dish Name'),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    TextField(
                      controller: pricePKRController,
                      decoration: InputDecoration(labelText: 'Price in PKR'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                    ),
                    TextField(
                      controller: quantityController,
                      decoration: InputDecoration(labelText: 'Quantity (kg)'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalInputFormatter()],
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: 'Type'),
                      items: _dishTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedType = newValue!;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: Text('Available'),
                      value: available,
                      onChanged: (bool? value) {
                        setState(() {
                          available = value!;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (kIsWeb) {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null) {
                            setState(() {
                              imageFile = result.files.first.bytes;
                              imageUrl = result.files.first.name;
                            });
                          }
                        } else {
                          final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              imageFile = File(pickedFile.path);
                            });
                          }
                        }
                      },
                      child: Text('Select Image'),
                    ),
                    if (kIsWeb && imageUrl != null)
                      Image.memory(imageFile),
                    if (!kIsWeb && imageFile != null)
                      Image.file(imageFile),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(currentItem == null ? 'Add' : 'Update'),
              onPressed: () {
                if (nameController.text.isEmpty ||
                    descriptionController.text.isEmpty ||
                    pricePKRController.text.isEmpty ||
                    quantityController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill out all fields')),
                  );
                  return;
                }

                if (!_isValidPrice(pricePKRController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid price')),
                  );
                  return;
                }

                if (!_isValidQuantity(quantityController.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid quantity')),
                  );
                  return;
                }

                if (currentItem == null) {
                  _addMenuItem(
                    nameController.text,
                    descriptionController.text,
                    pricePKRController.text,
                    quantityController.text,
                    selectedType,
                    restaurantName,
                    imageFile,
                  );
                } else {
                  _editMenuItem(
                      key!,
                      nameController.text,
                      descriptionController.text,
                      pricePKRController.text,
                      quantityController.text,
                      selectedType,
                      available,
                      imageFile,
                      imageUrl
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool _isValidPrice(String str) {
    final number = num.tryParse(str);
    return number != null;
  }

  bool _isValidQuantity(String str) {
    final number = num.tryParse(str);
    return number != null && number > 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu'),
      ),
      body: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return Dismissible(
            key: Key(item['key']),
            background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
            secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                _showAddMenuItemDialog(key: item['key'], currentItem: item);
                return false;
              } else {
                return await _showConfirmationDialog(context) ?? false;
              }
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.startToEnd) {
                _deleteMenuItem(item['key'], item['imageUrl']);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
              }
            },
            child: ListTile(
              leading: item['imageUrl'] != null
                  ? Image.network(
                item['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : null,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item['name']),
                  Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
                ],
              ),
              subtitle: Text('${item['description']} (${item['type']})'),
              trailing: Checkbox(
                value: item['available'],
                onChanged: (bool? value) {
                  setState(() {
                    item['available'] = value!;
                    _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], null, item['imageUrl']);
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenuItemDialog(),
        child: Icon(Icons.add),
        backgroundColor: Colors.amber[800],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }
}

class DecimalInputFormatter extends TextInputFormatter {
  final RegExp _regExp = RegExp(r'^\d*\.?\d*');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (_regExp.hasMatch(text)) {
      return newValue;
    } else {
      return oldValue;
    }
  }
}


//resturandId-CustomerId








// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//             'imageUrl': item['imageUrl'] as String?,
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   Future<String?> _uploadImage(dynamic imageFile, String restaurantId, String menuItemId) async {
//     try {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('menu_images/$restaurantId/$menuItemId.jpg');
//       UploadTask uploadTask;
//       if (kIsWeb) {
//         uploadTask = storageRef.putData(imageFile);
//       } else {
//         uploadTask = storageRef.putFile(imageFile);
//       }
//       final taskSnapshot = await uploadTask;
//       return await taskSnapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, dynamic imageFile) async {
//     final newItemRef = databaseRef.push();
//     String? imageUrl;
//
//     if (imageFile != null) {
//       imageUrl = await _uploadImage(imageFile, widget.restaurantId, newItemRef.key!);
//       if (imageUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
//         return;
//       }
//     }
//
//     final newMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName,
//       'imageUrl': imageUrl,
//     };
//
//     newItemRef.set(newMenuItem);
//
//     newMenuItem['key'] = newItemRef.key;
//     setState(() {
//       _menuItems.add(newMenuItem);
//     });
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, dynamic imageFile, String? oldImageUrl) async {
//     String? imageUrl = oldImageUrl;
//     if (imageFile != null) {
//       if (oldImageUrl != null) {
//         await _deleteImage(oldImageUrl);
//       }
//       imageUrl = await _uploadImage(imageFile, widget.restaurantId, key);
//       if (imageUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
//         return;
//       }
//     }
//
//     final updatedMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available,
//       'imageUrl': imageUrl,
//     };
//
//     databaseRef.child(key).update(updatedMenuItem);
//
//     setState(() {
//       final index = _menuItems.indexWhere((item) => item['key'] == key);
//       if (index != -1) {
//         _menuItems[index] = updatedMenuItem;
//         _menuItems[index]['key'] = key;
//       }
//     });
//   }
//
//   Future<void> _deleteImage(String imageUrl) async {
//     try {
//       final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
//       await storageRef.delete();
//     } catch (e) {
//       print('Error deleting image: $e');
//     }
//   }
//
//   void _deleteMenuItem(String key, String? imageUrl) async {
//     if (imageUrl != null) {
//       await _deleteImage(imageUrl);
//     }
//     databaseRef.child(key).remove();
//     setState(() {
//       _menuItems.removeWhere((item) => item['key'] == key);
//     });
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//     dynamic imageFile;
//     String? imageUrl = currentItem?['imageUrl'];
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                     ElevatedButton(
//                       onPressed: () async {
//                         if (kIsWeb) {
//                           final result = await FilePicker.platform.pickFiles();
//                           if (result != null) {
//                             setState(() {
//                               imageFile = result.files.first.bytes;
//                               imageUrl = result.files.first.name;
//                             });
//                           }
//                         } else {
//                           final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//                           if (pickedFile != null) {
//                             setState(() {
//                               imageFile = File(pickedFile.path);
//                             });
//                           }
//                         }
//                       },
//                       child: Text('Select Image'),
//                     ),
//                     if (kIsWeb && imageUrl != null)
//                       Image.memory(imageFile),
//                     if (!kIsWeb && imageFile != null)
//                       Image.file(imageFile),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 if (currentItem == null) {
//                   _addMenuItem(
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     restaurantName,
//                     imageFile,
//                   );
//                 } else {
//                   _editMenuItem(
//                       key!,
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       available,
//                       imageFile,
//                       imageUrl
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key'], item['imageUrl']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Checkbox(
//                 value: item['available'],
//                 onChanged: (bool? value) {
//                   setState(() {
//                     item['available'] = value!;
//                     _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], null, item['imageUrl']);
//                   });
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }
//






// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'dart:io';
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//             'imageUrl': item['imageUrl'] as String?,
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   Future<String?> _uploadImage(dynamic imageFile) async {
//     try {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//       UploadTask uploadTask;
//       if (kIsWeb) {
//         uploadTask = storageRef.putData(imageFile);
//       } else {
//         uploadTask = storageRef.putFile(imageFile);
//       }
//       final taskSnapshot = await uploadTask;
//       return await taskSnapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, dynamic imageFile, String? imageUrl) async {
//     if (imageFile != null) {
//       imageUrl = await _uploadImage(imageFile);
//       if (imageUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
//         return;
//       }
//     }
//
//     final newMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName,
//       'imageUrl': imageUrl,
//     };
//
//     final newItemRef = databaseRef.push();
//     newItemRef.set(newMenuItem);
//
//     newMenuItem['key'] = newItemRef.key;
//     setState(() {
//       _menuItems.add(newMenuItem);
//     });
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, dynamic imageFile, String? oldImageUrl) async {
//     String? imageUrl = oldImageUrl;
//     if (imageFile != null) {
//       if (oldImageUrl != null) {
//         await _deleteImage(oldImageUrl);
//       }
//       imageUrl = await _uploadImage(imageFile);
//       if (imageUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
//         return;
//       }
//     }
//
//     final updatedMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available,
//       'imageUrl': imageUrl,
//     };
//
//     databaseRef.child(key).update(updatedMenuItem);
//
//     setState(() {
//       final index = _menuItems.indexWhere((item) => item['key'] == key);
//       if (index != -1) {
//         _menuItems[index] = updatedMenuItem;
//         _menuItems[index]['key'] = key;
//       }
//     });
//   }
//
//   Future<void> _deleteImage(String imageUrl) async {
//     try {
//       final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
//       await storageRef.delete();
//     } catch (e) {
//       print('Error deleting image: $e');
//     }
//   }
//
//   void _deleteMenuItem(String key, String? imageUrl) async {
//     if (imageUrl != null) {
//       await _deleteImage(imageUrl);
//     }
//     databaseRef.child(key).remove();
//     setState(() {
//       _menuItems.removeWhere((item) => item['key'] == key);
//     });
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//     dynamic imageFile;
//     String? imageUrl = currentItem?['imageUrl'];
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                     ElevatedButton(
//                       onPressed: () async {
//                         if (kIsWeb) {
//                           final result = await FilePicker.platform.pickFiles();
//                           if (result != null) {
//                             setState(() {
//                               imageFile = result.files.first.bytes;
//                               imageUrl = result.files.first.name;
//                             });
//                           }
//                         } else {
//                           final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//                           if (pickedFile != null) {
//                             setState(() {
//                               imageFile = File(pickedFile.path);
//                             });
//                           }
//                         }
//                       },
//                       child: Text('Select Image'),
//                     ),
//                     if (kIsWeb && imageUrl != null)
//                       Image.memory(imageFile),
//                     if (!kIsWeb && imageFile != null)
//                       Image.file(imageFile),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 if (currentItem == null) {
//                   _addMenuItem(
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       restaurantName,
//                       imageFile,
//                       imageUrl
//                   );
//                 } else {
//                   _editMenuItem(
//                       key!,
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       available,
//                       imageFile,
//                       imageUrl
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key'], item['imageUrl']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Checkbox(
//                 value: item['available'],
//                 onChanged: (bool? value) {
//                   setState(() {
//                     item['available'] = value!;
//                     _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], null, item['imageUrl']);
//                   });
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }





// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//             'imageUrl': item['imageUrl'] as String?,
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   Future<String?> _uploadImage(File imageFile) async {
//     try {
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
//       final uploadTask = storageRef.putFile(imageFile);
//       final taskSnapshot = await uploadTask;
//       return await taskSnapshot.ref.getDownloadURL();
//     } catch (e) {
//       print('Error uploading image: $e');
//       return null;
//     }
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, File? imageFile) async {
//     String? imageUrl;
//     if (imageFile != null) {
//       imageUrl = await _uploadImage(imageFile);
//       if (imageUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
//         return;
//       }
//     }
//
//     final newMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName,
//       'imageUrl': imageUrl,
//     };
//
//     final newItemRef = databaseRef.push();
//     newItemRef.set(newMenuItem);
//
//     newMenuItem['key'] = newItemRef.key;
//     setState(() {
//       _menuItems.add(newMenuItem);
//     });
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, File? imageFile, String? oldImageUrl) async {
//     String? imageUrl = oldImageUrl;
//     if (imageFile != null) {
//       if (oldImageUrl != null) {
//         await _deleteImage(oldImageUrl);
//       }
//       imageUrl = await _uploadImage(imageFile);
//       if (imageUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image')));
//         return;
//       }
//     }
//
//     final updatedMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available,
//       'imageUrl': imageUrl,
//     };
//
//     databaseRef.child(key).update(updatedMenuItem);
//
//     setState(() {
//       final index = _menuItems.indexWhere((item) => item['key'] == key);
//       if (index != -1) {
//         _menuItems[index] = updatedMenuItem;
//         _menuItems[index]['key'] = key;
//       }
//     });
//   }
//
//   Future<void> _deleteImage(String imageUrl) async {
//     try {
//       final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
//       await storageRef.delete();
//     } catch (e) {
//       print('Error deleting image: $e');
//     }
//   }
//
//   void _deleteMenuItem(String key, String? imageUrl) async {
//     if (imageUrl != null) {
//       await _deleteImage(imageUrl);
//     }
//     databaseRef.child(key).remove();
//     setState(() {
//       _menuItems.removeWhere((item) => item['key'] == key);
//     });
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//     File? imageFile;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                     ElevatedButton(
//                       onPressed: () async {
//                         final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//                         if (pickedFile != null) {
//                           setState(() {
//                             imageFile = File(pickedFile.path);
//                           });
//                         }
//                       },
//                       child: Text('Select Image'),
//                     ),
//                     if (imageFile != null) Image.file(imageFile!),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 if (currentItem == null) {
//                   _addMenuItem(
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       restaurantName,
//                       imageFile
//                   );
//                 } else {
//                   _editMenuItem(
//                       key!,
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       available,
//                       imageFile,
//                       currentItem['imageUrl']
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key'], item['imageUrl']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Checkbox(
//                 value: item['available'],
//                 onChanged: (bool? value) {
//                   setState(() {
//                     item['available'] = value!;
//                     _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], null, item['imageUrl']);
//                   });
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }







// import 'dart:io' show File;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//   final ImagePicker _picker = ImagePicker();
//   XFile? _selectedImage;
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//             'imageUrl': item['imageUrl'] ?? '',
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   Future<String?> _uploadImage(File image, String uniqueKey) async {
//     try {
//       final storageRef = FirebaseStorage.instance.ref().child('menu_images').child('$uniqueKey.jpg');
//       final uploadTask = storageRef.putFile(image);
//       final snapshot = await uploadTask.whenComplete(() {});
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       print('Image upload error: $e');
//       return null;
//     }
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, String? imageUrl) {
//     final newMenuItemRef = databaseRef.push();
//     final newMenuItem = {
//       'key': newMenuItemRef.key,
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName,
//       'imageUrl': imageUrl ?? ''
//     };
//
//     newMenuItemRef.set(newMenuItem).then((_) {
//       setState(() {
//         _menuItems.add(newMenuItem);
//       });
//     });
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, String imageUrl) {
//     final updatedMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available,
//       'imageUrl': imageUrl
//     };
//
//     databaseRef.child(key).update(updatedMenuItem).then((_) {
//       setState(() {
//         final index = _menuItems.indexWhere((item) => item['key'] == key);
//         if (index != -1) {
//           _menuItems[index] = {
//             'key': key,
//             ...updatedMenuItem
//           };
//         }
//       });
//     });
//   }
//
//   void _deleteMenuItem(String key) {
//     databaseRef.child(key).remove().then((_) {
//       setState(() {
//         _menuItems.removeWhere((item) => item['key'] == key);
//       });
//     });
//   }
//
//   Future<void> _pickImage() async {
//     final pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//       maxWidth: 800,
//       maxHeight: 800,
//     );
//
//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = pickedFile;
//       });
//     }
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//     _selectedImage = null;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                     TextButton(
//                       onPressed: _pickImage,
//                       child: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
//                     ),
//                     if (_selectedImage != null)
//                       kIsWeb
//                           ? Image.network(_selectedImage!.path, height: 100, width: 100)
//                           : Image.file(File(_selectedImage!.path), height: 100, width: 100),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () async {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 String? imageUrl = currentItem?['imageUrl'];
//                 if (_selectedImage != null && !kIsWeb) {
//                   imageUrl = await _uploadImage(File(_selectedImage!.path), key ?? databaseRef.push().key!);
//                 }
//
//                 if (currentItem == null) {
//                   _addMenuItem(
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     restaurantName,
//                     imageUrl,
//                   );
//                 } else {
//                   _editMenuItem(
//                     key!,
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     available,
//                     imageUrl ?? '',
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (item['imageUrl'] != '')
//                     Image.network(item['imageUrl'], height: 50, width: 50, fit: BoxFit.cover),
//                   Checkbox(
//                     value: item['available'],
//                     onChanged: (bool? value) {
//                       setState(() {
//                         item['available'] = value!;
//                         _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], item['imageUrl']);
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }
//
//





// import 'dart:io' show File;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//   final ImagePicker _picker = ImagePicker();
//   XFile? _selectedImage;
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//             'imageUrl': item['imageUrl'] ?? '',
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   Future<String?> _uploadImage(File image, String uniqueKey) async {
//     try {
//       final storageRef = FirebaseStorage.instance.ref().child('menu_images').child('$uniqueKey.jpg');
//       final uploadTask = storageRef.putFile(image);
//       final snapshot = await uploadTask.whenComplete(() {});
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, String? imageUrl) {
//     final newMenuItemRef = databaseRef.push();
//     final newMenuItem = {
//       'key': newMenuItemRef.key,
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName,
//       'imageUrl': imageUrl ?? ''
//     };
//
//     newMenuItemRef.set(newMenuItem);
//
//     setState(() {
//       _menuItems.add(newMenuItem);
//     });
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, String imageUrl) {
//     databaseRef.child(key).update({
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available,
//       'imageUrl': imageUrl
//     });
//
//     setState(() {
//       final index = _menuItems.indexWhere((item) => item['key'] == key);
//       if (index != -1) {
//         _menuItems[index] = {
//           'key': key,
//           'name': name,
//           'description': description,
//           'pricePKR': pricePKR,
//           'quantity': quantity,
//           'type': type,
//           'available': available,
//           'imageUrl': imageUrl
//         };
//       }
//     });
//   }
//
//   void _deleteMenuItem(String key) {
//     databaseRef.child(key).remove();
//     setState(() {
//       _menuItems.removeWhere((item) => item['key'] == key);
//     });
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//     _selectedImage = null;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                     TextButton(
//                       onPressed: () async {
//                         final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//                         setState(() {
//                           _selectedImage = pickedFile;
//                         });
//                       },
//                       child: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
//                     ),
//                     if (_selectedImage != null)
//                       kIsWeb
//                           ? Image.network(_selectedImage!.path, height: 100, width: 100)
//                           : Image.file(File(_selectedImage!.path), height: 100, width: 100),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () async {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 String? imageUrl;
//                 if (_selectedImage != null && !kIsWeb) {
//                   final newMenuItemRef = databaseRef.push();
//                   key ??= newMenuItemRef.key;
//                   imageUrl = await _uploadImage(File(_selectedImage!.path), key!);
//                 }
//
//                 if (currentItem == null) {
//                   final newMenuItemRef = databaseRef.push();
//                   key = newMenuItemRef.key!;
//                   if (_selectedImage != null && !kIsWeb) {
//                     imageUrl = await _uploadImage(File(_selectedImage!.path), key!);
//                   }
//                   _addMenuItem(
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     restaurantName,
//                     imageUrl ?? '',
//                   );
//                 } else {
//                   _editMenuItem(
//                     key!,
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     available,
//                     imageUrl ?? currentItem!['imageUrl'] ?? '',
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (item['imageUrl'] != '')
//                     Image.network(item['imageUrl'], height: 50, width: 50, fit: BoxFit.cover),
//                   Checkbox(
//                     value: item['available'],
//                     onChanged: (bool? value) {
//                       setState(() {
//                         item['available'] = value!;
//                         _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], item['imageUrl']);
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }







// import 'dart:io' show File;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
//
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//   final ImagePicker _picker = ImagePicker();
//   XFile? _selectedImage;
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//             'imageUrl': item['imageUrl'] ?? '',
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   Future<String?> _uploadImage(File image) async {
//     try {
//       final storageRef = FirebaseStorage.instance.ref().child('menu_images').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
//       final uploadTask = storageRef.putFile(image);
//       final snapshot = await uploadTask.whenComplete(() {});
//       final downloadUrl = await snapshot.ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName, String? imageUrl) {
//     final newMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName,
//       'imageUrl': imageUrl ?? ''
//     };
//
//     setState(() {
//       _menuItems.add(newMenuItem);
//     });
//
//     databaseRef.push().set(newMenuItem);
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available, String? imageUrl) {
//     databaseRef.child(key).update({
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available,
//       'imageUrl': imageUrl ?? ''
//     });
//
//     setState(() {
//       final index = _menuItems.indexWhere((item) => item['key'] == key);
//       if (index != -1) {
//         _menuItems[index] = {
//           'key': key,
//           'name': name,
//           'description': description,
//           'pricePKR': pricePKR,
//           'quantity': quantity,
//           'type': type,
//           'available': available,
//           'imageUrl': imageUrl ?? ''
//         };
//       }
//     });
//   }
//
//   void _deleteMenuItem(String key) {
//     databaseRef.child(key).remove();
//     setState(() {
//       _menuItems.removeWhere((item) => item['key'] == key);
//     });
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//     _selectedImage = null;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                     TextButton(
//                       onPressed: () async {
//                         final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//                         setState(() {
//                           _selectedImage = pickedFile;
//                         });
//                       },
//                       child: Text(_selectedImage == null ? 'Select Image' : 'Change Image'),
//                     ),
//                     if (_selectedImage != null)
//                       kIsWeb
//                           ? Image.network(_selectedImage!.path, height: 100, width: 100)
//                           : Image.file(File(_selectedImage!.path), height: 100, width: 100),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () async {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 String? imageUrl;
//                 if (_selectedImage != null && !kIsWeb) {
//                   imageUrl = await _uploadImage(File(_selectedImage!.path));
//                 }
//
//                 if (currentItem == null) {
//                   _addMenuItem(
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     restaurantName,
//                     imageUrl,
//                   );
//                 } else {
//                   _editMenuItem(
//                     key!,
//                     nameController.text,
//                     descriptionController.text,
//                     pricePKRController.text,
//                     quantityController.text,
//                     selectedType,
//                     available,
//                     imageUrl,
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (item['imageUrl'] != '')
//                     Image.network(item['imageUrl'], height: 50, width: 50, fit: BoxFit.cover),
//                   Checkbox(
//                     value: item['available'],
//                     onChanged: (bool? value) {
//                       setState(() {
//                         item['available'] = value!;
//                         _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available'], item['imageUrl']);
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }






//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId, required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, dynamic>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, dynamic>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'key': key,
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//             'available': item['available'] ?? true,
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type, String restaurantName) {
//     final newMenuItem = {
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': true,
//       'restaurant_name': restaurantName
//     };
//
//     setState(() {
//       _menuItems.add(newMenuItem);
//     });
//
//     databaseRef.push().set(newMenuItem);
//   }
//
//   void _editMenuItem(String key, String name, String description, String pricePKR, String quantity, String type, bool available) {
//     databaseRef.child(key).update({
//       'name': name,
//       'description': description,
//       'pricePKR': pricePKR,
//       'quantity': quantity,
//       'type': type,
//       'available': available
//     });
//
//     setState(() {
//       final index = _menuItems.indexWhere((item) => item['key'] == key);
//       if (index != -1) {
//         _menuItems[index] = {
//           'key': key,
//           'name': name,
//           'description': description,
//           'pricePKR': pricePKR,
//           'quantity': quantity,
//           'type': type,
//           'available': available
//         };
//       }
//     });
//   }
//
//   void _deleteMenuItem(String key) {
//     databaseRef.child(key).remove();
//     setState(() {
//       _menuItems.removeWhere((item) => item['key'] == key);
//     });
//   }
//
//   void _showAddMenuItemDialog({String? key, Map<String, dynamic>? currentItem}) {
//     final TextEditingController nameController = TextEditingController(text: currentItem?['name'] ?? '');
//     final TextEditingController descriptionController = TextEditingController(text: currentItem?['description'] ?? '');
//     final TextEditingController pricePKRController = TextEditingController(text: currentItem?['pricePKR'] ?? '');
//     final TextEditingController quantityController = TextEditingController(text: currentItem?['quantity'] ?? '');
//     String selectedType = currentItem?['type'] ?? _dishTypes.first;
//     bool available = currentItem?['available'] ?? true;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(currentItem == null ? 'Add Dish' : 'Edit Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                     CheckboxListTile(
//                       title: Text('Available'),
//                       value: available,
//                       onChanged: (bool? value) {
//                         setState(() {
//                           available = value!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text(currentItem == null ? 'Add' : 'Update'),
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 if (currentItem == null) {
//                   _addMenuItem(
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       restaurantName
//                   );
//                 } else {
//                   _editMenuItem(
//                       key!,
//                       nameController.text,
//                       descriptionController.text,
//                       pricePKRController.text,
//                       quantityController.text,
//                       selectedType,
//                       available
//                   );
//                 }
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Menu'),
//       ),
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return Dismissible(
//             key: Key(item['key']),
//             background: Container(color: Colors.red, child: Icon(Icons.delete, color: Colors.white)),
//             secondaryBackground: Container(color: Colors.blue, child: Icon(Icons.edit, color: Colors.white)),
//             confirmDismiss: (direction) async {
//               if (direction == DismissDirection.endToStart) {
//                 _showAddMenuItemDialog(key: item['key'], currentItem: item);
//                 return false;
//               } else {
//                 return await _showConfirmationDialog(context) ?? false;
//               }
//             },
//             onDismissed: (direction) {
//               if (direction == DismissDirection.startToEnd) {
//                 _deleteMenuItem(item['key']);
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item['name']} deleted')));
//               }
//             },
//             child: ListTile(
//               title: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(item['name']),
//                   Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//                 ],
//               ),
//               subtitle: Text('${item['description']} (${item['type']})'),
//               trailing: Checkbox(
//                 value: item['available'],
//                 onChanged: (bool? value) {
//                   setState(() {
//                     item['available'] = value!;
//                     _editMenuItem(item['key'], item['name'], item['description'], item['pricePKR'], item['quantity'], item['type'], item['available']);
//                   });
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _showAddMenuItemDialog(),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
//
//   Future<bool?> _showConfirmationDialog(BuildContext context) {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Delete Confirmation'),
//           content: Text('Are you sure you want to delete this item?'),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text('Delete'),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }














// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class AddMenuScreen extends StatefulWidget {
//   final String restaurantId;
//   final String restaurantName;
//
//   AddMenuScreen({required this.restaurantId,required this.restaurantName});
//
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   late DatabaseReference databaseRef;
//   late String restaurantName;
//   final List<Map<String, String>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//
//   @override
//   void initState() {
//     super.initState();
//     databaseRef = FirebaseDatabase.instance.ref('Menu/${widget.restaurantId}');
//     _fetchMenuItems();
//     restaurantName = widget.restaurantName;
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, String>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type,String restaurantName) {
//     setState(() {
//       _menuItems.add({
//         'name': name,
//         'description': description,
//         'pricePKR': pricePKR,
//         'quantity': quantity,
//         'type': type,
//         'restaurant_name': restaurantName
//       });
//       databaseRef.push().set({
//         'name': name,
//         'description': description,
//         'pricePKR': pricePKR,
//         'quantity': quantity,
//         'type': type,
//         'restaurant_name': restaurantName
//       });
//     });
//   }
//
//   void _showAddMenuItemDialog() {
//     final TextEditingController nameController = TextEditingController();
//     final TextEditingController descriptionController = TextEditingController();
//     final TextEditingController pricePKRController = TextEditingController();
//     final TextEditingController quantityController = TextEditingController();
//     String selectedType = _dishTypes.first;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Add Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text('Add'),
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 _addMenuItem(
//                   nameController.text,
//                   descriptionController.text,
//                   pricePKRController.text,
//                   quantityController.text,
//                   selectedType,
//                   restaurantName
//                 );
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return ListTile(
//             title: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(item['name']!),
//                 Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//               ],
//             ),
//             subtitle: Text('${item['description']} (${item['type']})'),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddMenuItemDialog,
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue,
//       TextEditingValue newValue,
//       ) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_database/firebase_database.dart';
//
// class AddMenuScreen extends StatefulWidget {
//   @override
//   _AddMenuScreenState createState() => _AddMenuScreenState();
// }
//
// class _AddMenuScreenState extends State<AddMenuScreen> {
//   final databaseRef = FirebaseDatabase.instance.ref('Menu');
//   final List<Map<String, String>> _menuItems = [];
//   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchMenuItems();
//   }
//
//   void _fetchMenuItems() async {
//     databaseRef.onValue.listen((DatabaseEvent event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>?;
//       if (data != null) {
//         final List<Map<String, String>> menuItems = [];
//         data.forEach((key, value) {
//           final item = value as Map<dynamic, dynamic>;
//           menuItems.add({
//             'name': item['name'] as String,
//             'description': item['description'] as String,
//             'pricePKR': item['pricePKR'] as String,
//             'quantity': item['quantity'] as String,
//             'type': item['type'] as String,
//           });
//         });
//         setState(() {
//           _menuItems.clear();
//           _menuItems.addAll(menuItems);
//         });
//       }
//     });
//   }
//
//   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type) {
//     setState(() {
//       _menuItems.add({
//         'name': name,
//         'description': description,
//         'pricePKR': pricePKR,
//         'quantity': quantity,
//         'type': type,
//       });
//       databaseRef.push().set({
//         'name': name,
//         'description': description,
//         'pricePKR': pricePKR,
//         'quantity': quantity,
//         'type': type,
//       });
//     });
//   }
//
//   void _showAddMenuItemDialog() {
//     final TextEditingController nameController = TextEditingController();
//     final TextEditingController descriptionController = TextEditingController();
//     final TextEditingController pricePKRController = TextEditingController();
//     final TextEditingController quantityController = TextEditingController();
//     String selectedType = _dishTypes.first;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Add Dish'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: nameController,
//                       decoration: InputDecoration(labelText: 'Dish Name'),
//                     ),
//                     TextField(
//                       controller: descriptionController,
//                       decoration: InputDecoration(labelText: 'Description'),
//                     ),
//                     TextField(
//                       controller: pricePKRController,
//                       decoration: InputDecoration(labelText: 'Price in PKR'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     TextField(
//                       controller: quantityController,
//                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       inputFormatters: [DecimalInputFormatter()],
//                     ),
//                     DropdownButtonFormField<String>(
//                       value: selectedType,
//                       decoration: InputDecoration(labelText: 'Type'),
//                       items: _dishTypes.map((String type) {
//                         return DropdownMenuItem<String>(
//                           value: type,
//                           child: Text(type),
//                         );
//                       }).toList(),
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           selectedType = newValue!;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text('Add'),
//               onPressed: () {
//                 if (nameController.text.isEmpty ||
//                     descriptionController.text.isEmpty ||
//                     pricePKRController.text.isEmpty ||
//                     quantityController.text.isEmpty) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please fill out all fields')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidPrice(pricePKRController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid price')),
//                   );
//                   return;
//                 }
//
//                 if (!_isValidQuantity(quantityController.text)) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Please enter a valid quantity')),
//                   );
//                   return;
//                 }
//
//                 _addMenuItem(
//                   nameController.text,
//                   descriptionController.text,
//                   pricePKRController.text,
//                   quantityController.text,
//                   selectedType,
//                 );
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   bool _isValidPrice(String str) {
//     final number = num.tryParse(str);
//     return number != null;
//   }
//
//   bool _isValidQuantity(String str) {
//     final number = num.tryParse(str);
//     return number != null && number > 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: ListView.builder(
//         itemCount: _menuItems.length,
//         itemBuilder: (context, index) {
//           final item = _menuItems[index];
//           return ListTile(
//             title: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(item['name']!),
//                 Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
//               ],
//             ),
//             subtitle: Text('${item['description']} (${item['type']})'),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _showAddMenuItemDialog,
//         child: Icon(Icons.add),
//         backgroundColor: Colors.amber[800],
//       ),
//     );
//   }
// }
//
// class DecimalInputFormatter extends TextInputFormatter {
//   final RegExp _regExp = RegExp(r'^\d*\.?\d*');
//
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue,
//       TextEditingValue newValue,
//       ) {
//     final text = newValue.text;
//     if (_regExp.hasMatch(text)) {
//       return newValue;
//     } else {
//       return oldValue;
//     }
//   }
// }
//
//
//
//
//
//
//
//
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:firebase_database/firebase_database.dart';
// //
// // class AddMenuScreen extends StatefulWidget {
// //   @override
// //   _AddMenuScreenState createState() => _AddMenuScreenState();
// // }
// //
// // class _AddMenuScreenState extends State<AddMenuScreen> {
// //   final databaseRef = FirebaseDatabase.instance.ref('Menu');
// //   final List<Map<String, String>> _menuItems = [];
// //   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchMenuItems();
// //   }
// //
// //   void _fetchMenuItems() async {
// //     databaseRef.onValue.listen((DatabaseEvent event) {
// //       final data = event.snapshot.value as Map<dynamic, dynamic>?;
// //       if (data != null) {
// //         final List<Map<String, String>> menuItems = [];
// //         data.forEach((key, value) {
// //           final item = value as Map<dynamic, dynamic>;
// //           menuItems.add({
// //             'name': item['name'] as String,
// //             'description': item['description'] as String,
// //             'pricePKR': item['pricePKR'] as String,
// //             'quantity': item['quantity'] as String,
// //             'type': item['type'] as String,
// //           });
// //         });
// //         setState(() {
// //           _menuItems.clear();
// //           _menuItems.addAll(menuItems);
// //         });
// //       }
// //     });
// //   }
// //
// //   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type) {
// //     setState(() {
// //       _menuItems.add({
// //         'name': name,
// //         'description': description,
// //         'pricePKR': pricePKR,
// //         'quantity': quantity,
// //         'type': type,
// //       });
// //       databaseRef.push().set({
// //         'name': name,
// //         'description': description,
// //         'pricePKR': pricePKR,
// //         'quantity': quantity,
// //         'type': type,
// //       });
// //     });
// //   }
// //
// //   void _showAddMenuItemDialog() {
// //     final TextEditingController nameController = TextEditingController();
// //     final TextEditingController descriptionController = TextEditingController();
// //     final TextEditingController pricePKRController = TextEditingController();
// //     final TextEditingController quantityController = TextEditingController();
// //     String selectedType = _dishTypes.first;
// //
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Add Dish'),
// //           content: StatefulBuilder(
// //             builder: (BuildContext context, StateSetter setState) {
// //               return SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     TextField(
// //                       controller: nameController,
// //                       decoration: InputDecoration(labelText: 'Dish Name'),
// //                     ),
// //                     TextField(
// //                       controller: descriptionController,
// //                       decoration: InputDecoration(labelText: 'Description'),
// //                     ),
// //                     TextField(
// //                       controller: pricePKRController,
// //                       decoration: InputDecoration(labelText: 'Price in PKR'),
// //                       keyboardType: TextInputType.number,
// //                       inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
// //                     ),
// //                     TextField(
// //                       controller: quantityController,
// //                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
// //                       keyboardType: TextInputType.number,
// //                       inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
// //                     ),
// //                     DropdownButtonFormField<String>(
// //                       value: selectedType,
// //                       decoration: InputDecoration(labelText: 'Type'),
// //                       items: _dishTypes.map((String type) {
// //                         return DropdownMenuItem<String>(
// //                           value: type,
// //                           child: Text(type),
// //                         );
// //                       }).toList(),
// //                       onChanged: (String? newValue) {
// //                         setState(() {
// //                           selectedType = newValue!;
// //                         });
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             },
// //           ),
// //           actions: [
// //             TextButton(
// //               child: Text('Cancel'),
// //               onPressed: () {
// //                 Navigator.of(context).pop();
// //               },
// //             ),
// //             TextButton(
// //               child: Text('Add'),
// //               onPressed: () {
// //                 if (nameController.text.isEmpty ||
// //                     descriptionController.text.isEmpty ||
// //                     pricePKRController.text.isEmpty ||
// //                     quantityController.text.isEmpty) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Please fill out all fields')),
// //                   );
// //                   return;
// //                 }
// //
// //                 if (!_isValidPrice(pricePKRController.text)) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Please enter a valid price')),
// //                   );
// //                   return;
// //                 }
// //
// //                 if (!_isValidQuantity(quantityController.text)) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Please enter a valid quantity')),
// //                   );
// //                   return;
// //                 }
// //
// //                 _addMenuItem(
// //                   nameController.text,
// //                   descriptionController.text,
// //                   pricePKRController.text,
// //                   quantityController.text,
// //                   selectedType,
// //                 );
// //                 Navigator.of(context).pop();
// //               },
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   bool _isValidPrice(String str) {
// //     final number = num.tryParse(str);
// //     return number != null;
// //   }
// //
// //   bool _isValidQuantity(String str) {
// //     final number = num.tryParse(str);
// //     return number != null && number > 0.0 && number <= 1.0;
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: ListView.builder(
// //         itemCount: _menuItems.length,
// //         itemBuilder: (context, index) {
// //           final item = _menuItems[index];
// //           return ListTile(
// //             title: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(item['name']!),
// //                 Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
// //               ],
// //             ),
// //             subtitle: Text('${item['description']} (${item['type']})'),
// //           );
// //         },
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _showAddMenuItemDialog,
// //         child: Icon(Icons.add),
// //         backgroundColor: Colors.amber[800],
// //       ),
// //     );
// //   }
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
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:firebase_database/firebase_database.dart';
// //
// // class AddMenuScreen extends StatefulWidget {
// //   @override
// //   _AddMenuScreenState createState() => _AddMenuScreenState();
// // }
// //
// // class _AddMenuScreenState extends State<AddMenuScreen> {
// //
// //   final databaseRef = FirebaseDatabase.instance.ref('Menu');
// //   final List<Map<String, String>> _menuItems = [];
// //   final List<String> _dishTypes = ['Starter', 'Main Course', 'Dessert', 'Beverage'];
// //
// //   void _addMenuItem(String name, String description, String pricePKR, String quantity, String type) {
// //     setState(() {
// //       _menuItems.add({
// //         'name': name,
// //         'description': description,
// //         'pricePKR': pricePKR,
// //         'quantity': quantity,
// //         'type': type,
// //
// //       });
// //       databaseRef.push().set( {
// //         'name': name,
// //         'description': description,
// //         'pricePKR': pricePKR,
// //         'quantity': quantity,
// //         'type': type,
// //       });
// //
// //     });
// //   }
// //
// //   void _showAddMenuItemDialog() {
// //
// //     final TextEditingController nameController = TextEditingController();
// //     final TextEditingController descriptionController = TextEditingController();
// //     final TextEditingController pricePKRController = TextEditingController();
// //     final TextEditingController quantityController = TextEditingController();
// //     String selectedType = _dishTypes.first;
// //
// //     showDialog(
// //       context: context,
// //       builder: (BuildContext context) {
// //         return AlertDialog(
// //           title: Text('Add Dish'),
// //           content: StatefulBuilder(
// //             builder: (BuildContext context, StateSetter setState) {
// //               return SingleChildScrollView(
// //                 child: Column(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     TextField(
// //                       controller: nameController,
// //                       decoration: InputDecoration(labelText: 'Dish Name'),
// //                     ),
// //                     TextField(
// //                       controller: descriptionController,
// //                       decoration: InputDecoration(labelText: 'Description'),
// //                     ),
// //                     TextField(
// //                       controller: pricePKRController,
// //                       decoration: InputDecoration(labelText: 'Price in PKR'),
// //                       keyboardType: TextInputType.number,
// //                       inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
// //                     ),
// //                     TextField(
// //                       controller: quantityController,
// //                       decoration: InputDecoration(labelText: 'Quantity (kg)'),
// //                       keyboardType: TextInputType.number,
// //                       inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
// //                     ),
// //                     DropdownButtonFormField<String>(
// //                       value: selectedType,
// //                       decoration: InputDecoration(labelText: 'Type'),
// //                       items: _dishTypes.map((String type) {
// //                         return DropdownMenuItem<String>(
// //                           value: type,
// //                           child: Text(type),
// //                         );
// //                       }).toList(),
// //                       onChanged: (String? newValue) {
// //                         setState(() {
// //                           selectedType = newValue!;
// //                         });
// //                       },
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             },
// //           ),
// //           actions: [
// //             TextButton(
// //               child: Text('Cancel'),
// //               onPressed: () {
// //                 Navigator.of(context).pop();
// //               },
// //             ),
// //             TextButton(
// //               child: Text('Add'),
// //               onPressed: () {
// //                 if (nameController.text.isEmpty ||
// //                     descriptionController.text.isEmpty ||
// //                     pricePKRController.text.isEmpty ||
// //                     quantityController.text.isEmpty) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Please fill out all fields')),
// //                   );
// //                   return;
// //                 }
// //
// //                 if (!_isValidPrice(pricePKRController.text)) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Please enter a valid price')),
// //                   );
// //                   return;
// //                 }
// //
// //                 if (!_isValidQuantity(quantityController.text)) {
// //                   ScaffoldMessenger.of(context).showSnackBar(
// //                     SnackBar(content: Text('Please enter a valid quantity')),
// //                   );
// //                   return;
// //                 }
// //
// //                 _addMenuItem(
// //                   nameController.text,
// //                   descriptionController.text,
// //                   pricePKRController.text,
// //                   quantityController.text,
// //                   selectedType,
// //
// //                 );
// //                 Navigator.of(context).pop();
// //               },
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }
// //
// //   bool _isValidPrice(String str) {
// //     final number = num.tryParse(str);
// //     return number != null;
// //   }
// //
// //   bool _isValidQuantity(String str) {
// //     final number = num.tryParse(str);
// //     return number != null && number > 0.0 && number <= 1.0;
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: ListView.builder(
// //         itemCount: _menuItems.length,
// //         itemBuilder: (context, index) {
// //           final item = _menuItems[index];
// //           return ListTile(
// //             title: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(item['name']!),
// //                 Text('Rs.${item['pricePKR']} / ${item['quantity']}kg'),
// //               ],
// //             ),
// //             subtitle: Text('${item['description']} (${item['type']})'),
// //           );
// //         },
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _showAddMenuItemDialog,
// //         child: Icon(Icons.add),
// //         backgroundColor: Colors.amber[800],
// //       ),
// //     );
// //   }
// // }
