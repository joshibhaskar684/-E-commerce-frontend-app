import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/state_views.dart';

/// Change where the app sends API requests without rebuilding.
///
///  USB cable  → http://localhost:8085      (after: adb reverse tcp:8085 tcp:8085)
///  Same Wi-Fi → `http://<PC-IPv4>:8085`     (see `ipconfig` on the PC)
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _url;
  final _focus = FocusNode();
  bool _testing = false;
  String? _result;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: context.read<SettingsProvider>().baseUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    final url = SettingsProvider.normalizeUrl(_url.text);
    if (url.isEmpty) return;
    setState(() {
      _testing = true;
      _result = null;
    });
    try {
      final took = await ApiClient.instance.ping(url);
      setState(() {
        _ok = true;
        _result = 'Connected to $url in ${took.inMilliseconds} ms';
      });
    } on ApiException catch (e) {
      setState(() {
        _ok = false;
        _result = e.message;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final url = SettingsProvider.normalizeUrl(_url.text);
    if (url.isEmpty) return;
    await context.read<SettingsProvider>().setBaseUrl(url);
    if (!mounted) return;
    _url.text = url;
    showAppSnack(context, 'Server URL saved. Pull down to refresh screens.');
  }

  Future<void> _reset() async {
    await context.read<SettingsProvider>().resetBaseUrl();
    if (!mounted) return;
    setState(() {
      _url.text = AppConfig.defaultApiBaseUrl;
      _result = null;
    });
    showAppSnack(context, 'Reset to ${AppConfig.defaultApiBaseUrl}');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Server settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API Gateway URL', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Every request (login, products, cart…) is sent to this address. '
                    'It must point to the Spring Cloud API Gateway on your PC (port 8085).',
                    style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Text('In use now: ${settings.baseUrl}',
                      style: t.bodySmall?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _url,
                    focusNode: _focus,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'http://localhost:8085',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                    onSubmitted: (_) => _test(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.usb_rounded, size: 18),
                        label: const Text('USB (adb reverse)'),
                        onPressed: () => setState(() => _url.text = 'http://localhost:8085'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.wifi_rounded, size: 18),
                        label: const Text('Wi-Fi (PC IP)'),
                        onPressed: () {
                          _url.text = 'http://192.168.';
                          _url.selection = TextSelection.collapsed(offset: _url.text.length);
                          _focus.requestFocus();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testing ? null : _test,
                          icon: _testing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.network_check_rounded),
                          label: const Text('Test'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_ok ? AppColors.success : scheme.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_ok ? Icons.check_circle_rounded : Icons.error_rounded,
                              color: _ok ? AppColors.success : scheme.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_result!)),
                        ],
                      ),
                    ),
                  ],
                  if (settings.isCustomBaseUrl) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _reset, child: const Text('Reset to default')),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _HelpCard(
            icon: Icons.usb_rounded,
            title: 'Phone connected with USB',
            steps: [
              'Enable USB debugging on the phone and plug it in.',
              'On the PC run:  adb reverse tcp:8085 tcp:8085',
              'Use http://localhost:8085 here.',
              'Run adb reverse again every time you re-plug the cable.',
            ],
            command: 'adb reverse tcp:8085 tcp:8085',
          ),
          const SizedBox(height: 12),
          const _HelpCard(
            icon: Icons.wifi_rounded,
            title: 'Phone on the same Wi-Fi',
            steps: [
              'Connect the phone and PC to the same Wi-Fi network.',
              'On the PC run ipconfig and copy the IPv4 address (e.g. 192.168.1.5).',
              'Allow port 8085 in Windows Firewall (see README).',
              'Use http://<that-IP>:8085 here.',
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.icon, required this.title, required this.steps, this.command});

  final IconData icon;
  final String title;
  final List<String> steps;
  final String? command;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                if (command != null)
                  IconButton(
                    tooltip: 'Copy command',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: command!));
                      showAppSnack(context, 'Copied: $command');
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Expanded(child: Text(steps[i], style: t.bodyMedium)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
