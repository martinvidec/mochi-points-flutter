import 'eaty.dart';

class CartItem {
  final Eaty eaty;
  int quantity;

  CartItem(this.eaty, [this.quantity = 1]);

  double get totalPrice => eaty.price * quantity;
}
