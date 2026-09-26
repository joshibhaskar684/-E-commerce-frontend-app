import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../models/cart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/net_image.dart';
import '../../widgets/state_views.dart';
import '../cart/price_details_card.dart';

/// Checkout → Razorpay payment link.
///
/// Uses the same call as the website (redux-store/checkout/action.js):
///   POST /api/payments/{id}  →  { payment_link_url }
/// and opens the link in the browser. The delivery address is saved on the
/// phone (there is no address API on the backend yet).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _addressKey = 'saved_address';

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pincode = TextEditingController();
  final _line = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();

  Map<String, String>? _address;
  bool _editing = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _pincode, _line, _city, _state]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_addressKey);
    if (!mounted) return;
    if (raw != null) {
      try {
        final map = Map<String, String>.from(jsonDecode(raw) as Map);
        setState(() => _address = map);
        return;
      } catch (_) {}
    }
    // Pre-fill from the profile the first time.
    final auth = context.read<AuthProvider>();
    _name.text = auth.name ?? '';
    _phone.text = auth.profile?.mobileno ?? '';
    setState(() => _editing = true);
  }

  void _startEditing() {
    final a = _address ?? const {};
    _name.text = a['name'] ?? '';
    _phone.text = a['phone'] ?? '';
    _pincode.text = a['pincode'] ?? '';
    _line.text = a['line'] ?? '';
    _city.text = a['city'] ?? '';
    _state.text = a['state'] ?? '';
    setState(() => _editing = true);
  }

  Future<bool> _saveAddress() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    final map = {
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'pincode': _pincode.text.trim(),
      'line': _line.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, jsonEncode(map));
    if (mounted) {
      setState(() {
        _address = map;
        _editing = false;
      });
    }
    return true;
  }

  Future<void> _pay(Cart cart) async {
    if (_editing && !await _saveAddress()) {
      if (mounted) showAppSnack(context, 'Please complete your delivery address.');
      return;
    }
    if (_address == null) return;
    setState(() => _paying = true);
    try {
      // The website passes an order/purchase id; until an Order service
      // exists the cart id identifies what is being paid for.
      final result = await PaymentService().createPayment(cart.id ?? '');
      final link = result['payment_link_url'] as String?;
      if (!mounted) return;
      if (link != null && link.isNotEmpty) {
        await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
        if (!mounted) return;
        await _info(
          icon: Icons.open_in_new_rounded,
          title: 'Complete your payment',
          message: 'The Razorpay payment page opened in your browser. '
              'Your order will be confirmed once the payment succeeds.',
        );
      } else {
        await _info(
          icon: Icons.info_outline_rounded,
          title: 'Payment created',
          message: 'The server did not return a payment link.\n\n$result',
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      await _info(
        icon: Icons.payments_outlined,
        title: 'Payment unavailable',
        message: e.isNotFound || e.statusCode == 503
            ? 'The payment service (POST /api/payments/{id}) is not running on the backend yet. '
                'Your cart is saved, so you can try again later.'
            : e.message,
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _info({required IconData icon, required String title, required String message}) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(icon),
          title: Text(title),
          content: Text(message),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    if (cart == null || cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          actionLabel: 'Back',
          onAction: () => Navigator.pop(context),
        ),
      );
    }
    final summary = cart.effectiveSummary;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _Step(number: 1, title: 'Delivery address'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _editing || _address == null ? _addressForm() : _addressView(),
            ),
          ),
          const _Step(number: 2, title: 'Order summary'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (final item in cart.items)
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.white,
                          child: NetImage(item.productImage, fit: BoxFit.contain),
                        ),
                      ),
                      title: Text(item.productName ?? 'Product', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Qty ${item.quantity} × ${formatPrice(item.unitPrice)}'),
                      trailing: Text(formatPrice(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
          ),
          const _Step(number: 3, title: 'Payment method'),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.radio_button_checked_rounded),
                  title: Text('Pay online', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('UPI, cards, net banking & wallets via Razorpay'),
                  trailing: Icon(Icons.account_balance_wallet_outlined),
                ),
                Divider(indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.outlineVariant),
                const ListTile(
                  enabled: false,
                  leading: Icon(Icons.radio_button_unchecked_rounded),
                  title: Text('Cash on delivery'),
                  subtitle: Text('Coming soon'),
                  trailing: Icon(Icons.payments_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PriceDetailsCard(summary: summary, itemCount: cart.itemCount),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: FilledButton.icon(
          onPressed: _paying ? null : () => _pay(cart),
          icon: _paying
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.lock_rounded, size: 18),
          label: Text(_paying ? 'Processing…' : 'Pay ${formatPrice(summary.totalAmount, forceDecimals: true)}'),
        ),
      ),
    );
  }

  Widget _addressView() {
    final a = _address!;
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['name'] ?? '', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${a['line']}, ${a['city']}, ${a['state']} - ${a['pincode']}'),
              const SizedBox(height: 4),
              Text('Phone: ${a['phone']}', style: t.bodySmall),
            ],
          ),
        ),
        TextButton(onPressed: _startEditing, child: const Text('Change')),
      ],
    );
  }

  Widget _addressForm() {
    const gap = SizedBox(height: 12);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
            validator: Validators.name,
          ),
          gap,
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixIcon: Icon(Icons.phone_outlined),
              counterText: '',
            ),
            validator: Validators.mobile,
          ),
          gap,
          TextFormField(
            controller: _line,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'House no., building, street, area',
              prefixIcon: Icon(Icons.home_outlined),
            ),
            validator: (v) => Validators.required(v, 'Address'),
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => Validators.required(v, 'City'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _pincode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'Pincode', counterText: ''),
                  validator: Validators.pincode,
                ),
              ),
            ],
          ),
          gap,
          TextFormField(
            controller: _state,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'State'),
            validator: (v) => Validators.required(v, 'State'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _saveAddress, child: const Text('Save address')),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title});
  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
            child: Text('$number', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
