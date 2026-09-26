import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shell_controller.dart';
import '../../widgets/state_views.dart';

/// My orders (website: account/orders).
///
/// The backend OrderService folder is still empty, so there is no endpoint
/// to list orders yet. Once it exists, load them here the same way
/// CartService loads the cart.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'When you place an order, you can track it here.',
        actionLabel: 'Start shopping',
        onAction: () {
          final shell = context.read<ShellController>();
          Navigator.of(context).popUntil((r) => r.isFirst);
          shell.goTo(ShellTab.home);
        },
      ),
    );
  }
}
