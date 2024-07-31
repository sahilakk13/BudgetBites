class MenuItem {
  final String key;
  final String name;
  final String description;
  final double price;
  final double quantity;
  final String type;
  final bool available;
  final String imageUrl;

  MenuItem({
    required this.key,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.type,
    required this.available,
    required this.imageUrl,
  });

  factory MenuItem.fromMap(String key, Map<String, dynamic> map) {
    return MenuItem(
      key: key,
      name: map['name'],
      description: map['description'],
      price: double.parse(map['pricePKR']),
      quantity: double.parse(map['quantity']),
      type: map['type'],
      available: map['available'] ?? true,
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
