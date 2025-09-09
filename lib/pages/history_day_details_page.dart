import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../repositories/task_repository.dart';
import '../view_models/day_details_view_model.dart';

class HistoryDayDetailsPage extends StatelessWidget {
  const HistoryDayDetailsPage({super.key, required this.dateStr});

  /// format: yyyy-MM-dd
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<TaskRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/history');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            _formatFullDate(_parseYmdLocal(dateStr)),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: uid == null
            ? const _AuthRequired()
            : ChangeNotifierProvider(
          create: (_) {
            final vm = DayDetailsViewModel(
              repo: repo,
              userId: uid,
              dateStr: dateStr,
            );
            Future.microtask(vm.refresh);
            return vm;
          },
          child: const _DayDetailsBody(),
        ),
      ),
    );
  }
}

class _DayDetailsBody extends StatelessWidget {
  const _DayDetailsBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<DayDetailsViewModel>(
      builder: (context, vm, _) {
        if (vm.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null) {
          return Center(
            child: Text(
              l10n.errorLoadingDay,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        if (vm.tasks.isEmpty) {
          return const _EmptyDay();
        }

        final tasks = vm.tasks;
        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: tasks.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFF2A2A2A)),
              itemBuilder: (context, i) {
                final t = tasks[i];
                final isDone = t.status == 'done';

                // format created time (from createdAt) in local time
                final createdLocal =
                DateTime.fromMillisecondsSinceEpoch(t.createdAt).toLocal();
                final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
                final l = MaterialLocalizations.of(context);
                final createdTime =
                l.formatTimeOfDay(TimeOfDay.fromDateTime(createdLocal), alwaysUse24HourFormat: use24h);

                // optional due date text (if dueDate exists)
                String? dueText;
                if (t.dueDate != null) {
                  final dueLocal = DateTime.fromMillisecondsSinceEpoch(t.dueDate!).toLocal();
                  final dueTime =
                  l.formatTimeOfDay(TimeOfDay.fromDateTime(dueLocal), alwaysUse24HourFormat: use24h);
                  final dueDate =
                      '${dueLocal.year.toString().padLeft(4, '0')}-${dueLocal.month.toString().padLeft(2, '0')}-${dueLocal.day.toString().padLeft(2, '0')}';
                  dueText = ' • Due: $dueDate $dueTime'; // localize label if you like
                }

                return ListTile(
                  title: Text(
                    t.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    dueText == null ? createdTime : '$createdTime$dueText',
                    style: const TextStyle(
                      color: Color(0xFFB5B5B5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isDone ? const Color(0xFFFF9800) : const Color(0xFF6B6B6B),
                  ),
                );
              },
          ),
        );
      },
    );
  }
}

// helpers + tiny UI

DateTime _parseYmdLocal(String s) {
  final parts = s.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

String _formatFullDate(DateTime dt) {
  const months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l10n.emptyDayTitle,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFCCCCCC)),
      ),
    );
  }
}

class _AuthRequired extends StatelessWidget {
  const _AuthRequired();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Text(
        l10n.authRequiredDay,
        style: const TextStyle(color: Color(0xFFCCCCCC)),
      ),
    );
  }
}
