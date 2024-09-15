import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import 'package:provider/provider.dart';
import '../providers/mochi_point_account_provider.dart';

class CartView extends StatelessWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onRemove;
  final Function(CartItem) onAdd;
  final double totalPoints;

  const CartView({
    Key? key,
    required this.cartItems,
    required this.onRemove,
    required this.onAdd,
    required this.totalPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountProvider = Provider.of<MochiPointAccountProvider>(context);
    double totalPrice = cartItems.fold(0, (sum, item) => sum + item.eaty.price * item.quantity);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return ListTile(
                title: Text(item.eaty.name),
                subtitle: Text('${item.eaty.price} Punkte x ${item.quantity}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () => onRemove(item),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => onAdd(item),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Gesamtpreis: $totalPrice Punkte'),
              ElevatedButton(
                child: Text('Kaufen'),
                onPressed: cartItems.isEmpty || totalPrice > accountProvider.balance
                    ? null
                    : () async {
                        if (await accountProvider.deductPoints(totalPrice)) {
                          // Clear the cart and show a success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Kauf erfolgreich!')),
                          );
                          // You might want to clear the cart here
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Nicht genug Punkte!')),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
