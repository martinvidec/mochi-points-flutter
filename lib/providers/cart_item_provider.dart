import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/eaty.dart';

class CartItemProvider extends ChangeNotifier {
  final List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  void addToCart(Eaty eaty) {
    int index = _cartItems.indexWhere((item) => item.eaty.name == eaty.name);
    if (index != -1) {
      _cartItems[index].quantity++;
    } else {
      _cartItems.add(CartItem(eaty));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _cartItems.remove(item);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  double get totalPrice => _cartItems.fold(0, (total, item) => total + item.totalPrice);
}

