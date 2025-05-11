import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/product_provider.dart';
import 'ProductDetailDialog.dart';

class YourStorePage extends StatelessWidget {
  final String currentUserId;

  const YourStorePage({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final userProducts = provider.getUserProducts(currentUserId);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Products')),
      body: userProducts.isEmpty
          ? const Center(child: Text('You have not posted any products.'))
          : ListView.builder(
        itemCount: userProducts.length,
        itemBuilder: (context, index) {
          final product = userProducts[index];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Image.network(product.imageId.first, width: 60, height: 60, fit: BoxFit.cover),
              title: Text(product.name),
              subtitle: Text('RM ${product.price.toStringAsFixed(2)} • ${product.conditionLabel}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final updated = await showDialog(
                        context: context,
                        builder: (_) => ProductEditDialog(product: product),
                      );
                      if (updated == true) {
                        provider.fetchProducts(); // 重新获取数据
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Product'),
                          content: const Text('Are you sure you want to delete this product?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await provider.deleteProduct(product.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
