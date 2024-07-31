class Restaurant {
  String restaurantId;
  String name;

  Restaurant({required this.restaurantId, required this.name});

  factory Restaurant.fromMap(Map<dynamic, dynamic> data) {
    return Restaurant(
      restaurantId: data['restaurant_id'],
      name: data['restaurant_name'],
    );
  }
}
