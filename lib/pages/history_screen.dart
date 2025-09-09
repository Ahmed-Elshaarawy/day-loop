import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../repositories/task_repository.dart';
import '../widgets/history_day_card.dart';
import '../view_models/history_view_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<TaskRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          l10n.historyTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid == null
          ? const _AuthRequired()
          : ChangeNotifierProvider(
              create: (_) {
                final vm = HistoryViewModel(repo, uid);
                // initial load
                Future.microtask(vm.refresh);
                return vm;
              },
              child: Consumer<HistoryViewModel>(
                builder: (context, vm, _) {
                  final l10n = AppLocalizations.of(context)!;

                  // 👉 before _loadedOnce: show loader (avoid empty flash)
                  if (!vm.loadedOnce && vm.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // first load finished with error and no data
                  if (vm.error != null && vm.tasks.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.errorLoadingHistory,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  // true empty (after first load)
                  if (vm.loadedOnce && vm.tasks.isEmpty) {
                    return const _EmptyHistory();
                  }

                  final grouped = vm.groupedByDay;
                  final keys = vm.sortedDayKeysDesc;

                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: vm.refresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: keys.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            final dateStr = keys[i];
                            final dayTasks = grouped[dateStr]!;
                            return HistoryDayCard(
                              day: _parseYmdLocal(dateStr),
                              tasks: dayTasks,
                              onTap: () =>
                                  context.push('/history/day/$dateStr'),
                            );
                          },
                        ),
                      ),
                      if (vm.loading)
                        const Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

// ---- helpers / small UI ----

DateTime _parseYmdLocal(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative illustration
            SizedBox(
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        radius: 0.85,
                        colors: [
                          Color(0x22FF9800),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Subtle card behind the icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2B2B2B), Color(0xFF1F1F1F)],
                      ),
                      border: Border.all(color: Colors.white12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.45),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFFF9800),
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              l10n.emptyHistoryTitle, // e.g. "No history yet."
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: .2,
              ),
            ),

            const SizedBox(height: 10),

            // Subtitle
            Text(
              l10n.emptyHistorySubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8B8B8),
                fontSize: 14.5,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Primary CTA: go start recording (to Home)
            SizedBox(
              width: double.infinity,
              child: _GradientButton(
                onPressed: () => context.go('/home'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mic, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      l10n.recordJourneyButton,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        l10n.authRequiredHistory,
        style: const TextStyle(color: Color(0xFFCCCCCC)),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9800).withOpacity(.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

