import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_item_provider.dart';

class CartItemPage extends StatelessWidget {
  const CartItemPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Warenkorb'),
      ),
      body: ListView.builder(
        itemCount: cartProvider.cartItems.length,
        itemBuilder: (context, index) {
          final item = cartProvider.cartItems[index];
          return ListTile(
            title: Text(item.eaty.name),
            subtitle: Text('Menge: ${item.quantity}'),
            trailing: Text('${item.eaty.price * item.quantity} €'),
            onTap: () {
              // Handle item tap if needed
            },
          );
        },
      ),
    );
  }
}
