import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../state/app_state.dart';
import '../models.dart';
import '../l10n/strings.dart';
import 'ui_helpers.dart';

class SettlementScreen extends StatelessWidget {
  const SettlementScreen({super.key});

  void _sharePlan(
      BuildContext context, AppState state, AppStrings s, NumberFormat fmt) {
    final settlements = state.settlements;
    if (settlements.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('📋 ${s.settlementTitle}');
    buffer.writeln('-------------------');

    for (var i = 0; i < settlements.length; i++) {
      final set = settlements[i];
      final from = state.people.firstWhere((p) => p.id == set.fromId).name;
      final to = state.people.firstWhere((p) => p.id == set.toId).name;
      buffer.writeln('${i + 1}. $from ➔ $to: ${fmt.format(set.amount)}');
    }

    buffer.writeln('\n${s.appTitle} ✨');
    Share.share(buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final settlements = state.settlements;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      body: Stack(
        children: [
          // ── Background Ambient Glows ─────────────────────────────────
          if (isDark) ...[
            _ambientGlow(
                top: -100,
                right: -100,
                color: cs.primary,
                opacity: 0.15,
                size: 400),
            _ambientGlow(
                bottom: 100,
                left: -100,
                color: Colors.purpleAccent,
                opacity: 0.1,
                size: 350),
            _ambientGlow(
                top: 250,
                left: 100,
                color: Colors.blueAccent,
                opacity: 0.08,
                size: 250),
          ] else ...[
            _ambientGlow(
                top: -100,
                right: -100,
                color: cs.primary,
                opacity: 0.1,
                size: 400),
            _ambientGlow(
                bottom: 100,
                left: -100,
                color: Colors.purpleAccent,
                opacity: 0.08,
                size: 350),
          ],

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : Colors.black.withValues(alpha: 0.05),
                                width: 0.5),
                          ),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (settlements.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        onPressed: () =>
                            _sharePlan(context, state, s, currencyFormat),
                        icon: Icon(Icons.share_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E)),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  title: Text(
                    s.settlementTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontFamily: 'Outfit',
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: const SizedBox(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Algorithm info card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF7B61FF)
                                      .withValues(alpha: 0.15),
                                  const Color(0xFF7B61FF)
                                      .withValues(alpha: 0.05),
                                ],
                              ),
                              border: Border.all(
                                color: const Color(0xFF7B61FF)
                                    .withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF7B61FF)
                                        .withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(Icons.auto_awesome,
                                      color: Color(0xFF7B61FF), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.greedyAlgo,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF7B61FF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        s.greedySubtitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.5)
                                              : Colors.black
                                                  .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF7B61FF)
                                        .withValues(alpha: 0.2),
                                  ),
                                  child: Text(
                                    '${settlements.length} ${s.times}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF7B61FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      settlements.isEmpty
                          ? _buildAllSettled(context, s, isDark)
                          : Column(
                              children: settlements.map((set) {
                                final from = state.people
                                    .firstWhere((p) => p.id == set.fromId);
                                final to = state.people
                                    .firstWhere((p) => p.id == set.toId);
                                return _SettlementCard(
                                  from: from,
                                  to: to,
                                  amount: set.amount,
                                  currencyFormat: currencyFormat,
                                  onSettle: () {
                                    state.settleDebt(
                                        set.fromId, set.toId, set.amount,
                                        shouldClear: false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(s.settleDone),
                                        backgroundColor:
                                            const Color(0xFF7B61FF),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  s: s,
                                  isDark: isDark,
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllSettled(BuildContext context, AppStrings s, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 60),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D4FF).withValues(alpha: 0.08),
                const Color(0xFF7B61FF).withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                width: 0.5),
          ),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF7B61FF)],
                ).createShader(b),
                child: const Icon(Icons.check_circle_outline,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                s.allSettled,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                s.allSettledSubtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ambientGlow(
      {double? top,
      double? bottom,
      double? left,
      double? right,
      required Color color,
      required double opacity,
      required double size}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.1),
          duration: const Duration(seconds: 5),
          builder: (context, scale, _) => Container(
            width: size * scale,
            height: size * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                color.withValues(alpha: opacity),
                Colors.transparent
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Person from;
  final Person to;
  final double amount;
  final NumberFormat currencyFormat;
  final VoidCallback onSettle;
  final AppStrings s;
  final bool isDark;

  const _SettlementCard({
    required this.from,
    required this.to,
    required this.amount,
    required this.currencyFormat,
    required this.onSettle,
    required this.s,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.03),
                  isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.black.withValues(alpha: 0.01),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 0.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // From avatar
                    _Avatar(
                        name: from.name,
                        colorIndex: from.colorIndex,
                        isDark: isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            currencyFormat.format(amount),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A2E),
                              fontFamily: 'Outfit',
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // To avatar
                    _Avatar(
                        name: to.name,
                        colorIndex: to.colorIndex,
                        isDark: isDark),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(s.settleNow.toUpperCase(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 12,
                                  fontFamily: 'Outfit')),
                          onPressed: onSettle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF7B61FF).withValues(alpha: 0.2)
                                : const Color(0xFF7B61FF),
                            foregroundColor:
                                isDark ? const Color(0xFF7B61FF) : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF7B61FF).withValues(alpha: 0.5)
                                      : Colors.transparent),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<AppState>().remindPerson(from.id, amount);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reminder sent to ${from.name}!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12),
                          ),
                          child: Icon(Icons.notifications_active_rounded,
                              size: 18,
                              color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final int colorIndex;
  final bool isDark;

  const _Avatar(
      {required this.name, required this.colorIndex, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = UIHelpers.getAvatarColor(colorIndex);
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black87,
              fontFamily: 'Outfit'),
        ),
      ],
    );
  }
}
