import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../base/liquid_background.dart';

class MainScreenScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget> children;
  final Widget? fab;
  final Widget? body;
  final EdgeInsetsGeometry? padding;
  final List<Widget>? appBarActions;
  final PreferredSizeWidget? appBarBottom;
  final bool showAvatar;
  final bool centerTitle;

  const MainScreenScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.children,
    this.fab,
    this.body,
    this.padding,
    this.appBarActions,
    this.appBarBottom,
    this.showAvatar = true,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = context.watch<AppState>();
    final user = state.currentUser;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      appBar: AppBar(
        title: titleWidget ??
            Text(title ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                )),
        backgroundColor: Colors.transparent,
        centerTitle: centerTitle,
        elevation: 0,
        bottom: appBarBottom,
        actions: [
          if (appBarActions != null) ...appBarActions!,
          if (showAvatar) _buildAvatar(context, user),
        ],
      ),
      body: Stack(
        children: [
          const LiquidBackground(),
          if (body != null)
            Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
              child: body!,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                final horizontalPadding =
                    isWide ? (constraints.maxWidth - 600) / 2 : 16.0;

                return ListView(
                  padding: padding ??
                      EdgeInsets.symmetric(
                          horizontal: horizontalPadding, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ...children,
                    const SizedBox(height: 100), // Spacing for FAB/BottomNav
                  ],
                );
              },
            ),
        ],
      ),
      floatingActionButton: fab,
    );
  }

  Widget _buildAvatar(BuildContext context, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    final avatarUrl = user.photoURL;

    return GestureDetector(
      onTap: () => _showLogoutDialog(context, user),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(user),
                    )
                  : _buildDefaultAvatar(user),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, dynamic user) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: isDark ? const Color(0xFF1E1E30) : Colors.white,
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        s.cancel,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AppState>().signOut();
                      },
                      child: Text(
                        'Logout',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
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

  Widget _buildDefaultAvatar(dynamic user) {
    final name = user?.displayName ?? '?';
    return Container(
      color: Colors.indigo,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
