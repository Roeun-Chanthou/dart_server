class ProductDS {
  ProductDS._();

  static final ProductDS _instance = ProductDS._();

  factory ProductDS() => _instance;

  final List<Map<String, dynamic>> _products = [
    {
      'id': 1,
      'title': 'Product 1',
      'price': 29.99,
      'detail': 'Detail of Product 1',
      'image': 'public/images/products/product1.png',
    },
    {
      'id': 2,
      'title': 'Product 2',
      'price': 49.99,
      'detail': 'Detail of Product 2',
      'image': 'public/images/products/product2.png',
    },
  ];

  List<Map<String, dynamic>> get products => _products;

  Map<String, dynamic>? get lastOrNull =>
      _products.isNotEmpty ? _products.last : null;

  void add(Map<String, dynamic> product) {
    _products.add(product);
  }
}
