import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';

/// Centralized open/resolved counts with lightweight polling.
class SupportCountsNotifier extends ChangeNotifier {
  int _open = 0;
  int _resolved = 0;
  Timer? _timer;

  int get open => _open;
  int get resolved => _resolved;

  void setCounts(int open, int resolved) {
    if (open == _open && resolved == _resolved) return;
    _open = open;
    _resolved = resolved;
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      final counts = await DatabaseService.getSupportCounts();
      if (counts != null) {
        setCounts(counts['open'] ?? 0, counts['resolved'] ?? 0);
      }
    } catch (_) {
      // ignore
    }
  }

  void start({Duration interval = const Duration(seconds: 20)}) {
    _timer?.cancel();
    // Immediate first refresh
    // Fire and forget; no need to await here
    unawaited(refresh());
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Inherited provider for SupportCountsNotifier without external deps.
class SupportCountsProvider extends InheritedNotifier<SupportCountsNotifier> {
  const SupportCountsProvider({super.key, required SupportCountsNotifier super.notifier, required super.child});

  static SupportCountsNotifier? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SupportCountsProvider>()?.notifier;
  }

  static SupportCountsNotifier of(BuildContext context) {
    final n = maybeOf(context);
    assert(n != null, 'SupportCountsProvider not found in context');
    return n!;
  }
}

/// Scope widget that owns the notifier lifecycle.
class SupportCountsScope extends StatefulWidget {
  final Widget child;
  const SupportCountsScope({super.key, required this.child});

  @override
  State<SupportCountsScope> createState() => _SupportCountsScopeState();
}

class _SupportCountsScopeState extends State<SupportCountsScope> {
  late final SupportCountsNotifier _notifier = SupportCountsNotifier()..start();

  @override
  Widget build(BuildContext context) {
    return SupportCountsProvider(notifier: _notifier, child: widget.child);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }
}
