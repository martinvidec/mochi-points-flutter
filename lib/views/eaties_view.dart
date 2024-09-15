import 'package:flutter/material.dart';
import '../models/eaty.dart';

class EatiesView extends StatelessWidget {
  final List<Eaty> eaties;
  final double totalPoints;
  final Function(Eaty) onAddToCart;
  final Function(Eaty) onEdit;
  final Function(Eaty) onDelete;

  const EatiesView({
    Key? key,
    required this.eaties,
    required this.totalPoints,
    required this.onAddToCart,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: eaties.length,
      itemBuilder: (context, index) {
        final eaty = eaties[index];
        return ListTile(
          title: Text(eaty.name),
          subtitle: Text('${eaty.price} Punkte'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => onEdit(eaty),
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => onDelete(eaty),
              ),
              IconButton(
                icon: Icon(Icons.add_shopping_cart),
                onPressed: totalPoints >= eaty.price ? () => onAddToCart(eaty) : null,
                color: totalPoints >= eaty.price ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
