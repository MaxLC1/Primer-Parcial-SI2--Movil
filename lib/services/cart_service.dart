import 'package:flutter/foundation.dart';

class CartItem {
  final int productoId;
  final String nombre;
  final double precioUnitario;
  int cantidad;
  
  // Valores fijos temporales para enviar a la API
  final int tallaId = 1; 
  final int colorId = 1;

  CartItem({
    required this.productoId,
    required this.nombre,
    required this.precioUnitario,
    this.cantidad = 1,
  });

  double get subtotal => precioUnitario * cantidad;
}

class CartService extends ChangeNotifier {
  // Patrón Singleton para mantener el estado global sin dependencias extra
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  void addItem(int productoId, String nombre, double precioUnitario) {
    // Verificar si ya existe en el carrito
    final existingIndex = _items.indexWhere((item) => item.productoId == productoId);
    if (existingIndex >= 0) {
      _items[existingIndex].cantidad += 1;
    } else {
      _items.add(CartItem(
        productoId: productoId,
        nombre: nombre,
        precioUnitario: precioUnitario,
      ));
    }
    notifyListeners();
  }

  void removeItem(int productoId) {
    _items.removeWhere((item) => item.productoId == productoId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
