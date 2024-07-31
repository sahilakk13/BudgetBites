import 'package:flutter/material.dart';
import 'CustomerMenuScreen.dart';
import 'CustomerHomeScreen.dart';
import '../../Models/MenuItem.dart';
import '../../Models/Restaurant.dart';




class AllRestaurantsPage extends StatelessWidget {
  final List<Restaurant> restaurants;
  final String customerId;
  final String customerName;

  AllRestaurantsPage({required this.restaurants,required this.customerId,required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Restaurants'),
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
      body: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          return RestaurantTile(
            restaurant: restaurants[index],
            customerId: customerId,
            customerName: customerName,
          );
        },
      ),
    );
  }
}






class RestaurantTile extends StatelessWidget {
  final Restaurant restaurant;
  final String customerId;
  final String customerName;

  RestaurantTile({required this.restaurant,required this.customerId,required this.customerName});

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
              builder: (context) => MenuScreen(restaurantId: restaurant.restaurantId, restaurantName: restaurant.name,customerId: customerId,customerName:customerName,),
            ),
          );
        },
      ),
    );
  }
}



