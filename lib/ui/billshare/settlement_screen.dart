import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../state/app_state.dart';
import '../../models.dart';
import '../../l10n/strings.dart';
import '../ui_helpers.dart';
import '../widgets/common_widgets.dart';
import '../../services/log_service.dart';

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
      try {
        final from = state.people.firstWhere((p) => p.id == set.fromId).name;
        final to = state.people.firstWhere((p) => p.id == set.toId).name;
        buffer.writeln('${i + 1}. $from ➔ $to: ${fmt.format(set.amount)}');
      } catch (e) {
        continue;
      }
    }

    buffer.writeln('\n${s.appTitle} ✨');
    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = AppStrings.of(context);
    final settlements = state.settlements;
    final currencyFormat =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      body: Stack(
        children: [
          const LiquidBackground(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                actions: [
                  if (settlements.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: IconButton(
                        onPressed: () =>
                            _sharePlan(context, state, s, currencyFormat),
                        icon: const Icon(Icons.share_rounded),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(56, 0, 56, 16),
                  title: Text(
                    s.settlementTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildAlgoInfo(s, isDark, settlements.length),
                ),
              ),
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.crossAxisExtent > 700;
                  final crossAxisCount = isWide ? 2 : 1;

                  final validSettlements = settlements.where((set) {
                    return state.people.any((p) => p.id == set.fromId) &&
                        state.people.any((p) => p.id == set.toId);
                  }).toList();

                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: validSettlements.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildAllSettled(context, s, isDark))
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 240,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final set = validSettlements[i];
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
                                    final involvement = (set.fromId == (state.me?.id ?? '') || set.toId == (state.me?.id ?? ''));
                                    if (involvement && state.accounts.isNotEmpty) {
                                      _showAccountPicker(context, state, set);
                                    } else {
                                      state.settleDebt(
                                          set.fromId, set.toId, set.amount,
                                          shouldClear: false);
                                    }
                                  },
                                  s: s,
                                  isDark: isDark,
                                );
                              },
                              childCount: validSettlements.length,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlgoInfo(AppStrings s, bool isDark, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF7B61FF), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.greedyAlgo,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7B61FF))),
                Text(s.greedySubtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black54)),
              ],
            ),
          ),
          Text('$count',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7B61FF))),
        ],
      ),
    );
  }

  void _showAccountPicker(BuildContext context, AppState state, Settlement set) {
    UIHelpers.showAccountPicker(
      context: context,
      state: state,
      onSelected: (acc) {
        state.settleDebt(set.fromId, set.toId, set.amount, sourceAccountId: acc.id);
      },
    );
  }

  Widget _buildAllSettled(BuildContext context, AppStrings s, bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
          const SizedBox(height: 12),
          Text(s.allSettled,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
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
    const accentColor = Color(0xFF7B61FF);
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatarsSection(accentColor),
          const SizedBox(height: 12),
          _buildAmountSection(accentColor),
          const SizedBox(height: 12),
          _buildActions(context, accentColor),
        ],
      ),
    );
  }

  Widget _buildAvatarsSection(Color accentColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 40,
          right: 40,
          child: Container(
            height: 1.5,
            color: accentColor.withValues(alpha: 0.08),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Avatar(person: from, isDark: isDark),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.02)),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: accentColor),
            ),
            _Avatar(person: to, isDark: isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountSection(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accentColor.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.oweLabel,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(width: 6),
          Text(currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
              )),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Color accentColor) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onSettle,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(s.settleNow,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                )),
          ),
        ),
        const SizedBox(width: 8),
        _ActionSmallButton(
          onPressed: () {
            context.read<AppState>().remindPerson(from.id, amount);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.remindedUser.replaceAll('{name}', from.name),
                    style: const TextStyle(fontSize: 13)),
                behavior: SnackBarBehavior.floating,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          icon: Icons.notifications_active_rounded,
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ActionSmallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final bool isDark;
  const _ActionSmallButton(
      {required this.onPressed, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon,
              size: 18, color: isDark ? Colors.white70 : Colors.black54),
        ),
      );
}

class _Avatar extends StatelessWidget {
  final Person person;
  final bool isDark;
  const _Avatar({required this.person, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = UIHelpers.getAvatarColor(person.colorIndex);
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            image: person.avatarUrl.isNotEmpty
                ? DecorationImage(
                    image: person.avatarUrl.startsWith('http')
                        ? NetworkImage(person.avatarUrl)
                        : (File(person.avatarUrl).existsSync()
                                ? FileImage(File(person.avatarUrl))
                                : const AssetImage(
                                    'assets/images/empty_state.png'))
                            as ImageProvider,
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) =>
                        log.warning('Avatar image error: $exception'),
                  )
                : null,
          ),
          child: person.avatarUrl.isEmpty
              ? Center(
                  child: Text(person.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)))
              : null,
        ),
        const SizedBox(height: 4),
        Text(person.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white70 : Colors.black87,
            )),
      ],
    );
  }
}
