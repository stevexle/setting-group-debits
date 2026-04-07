import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import '../../../l10n/strings.dart';
import '../base/liquid_background.dart';
import '../base/glass_container.dart';
import '../elements/my_profile_modal.dart';

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
      extendBodyBehindAppBar: true,
      backgroundColor:
          isDark ? const Color(0xFF0E0E1A) : const Color(0xFFF5F5FF),
      appBar: AppBar(
        toolbarHeight: 32, // Ultra thin
        titleSpacing: 0, // No side padding
        title: titleWidget ??
            Text(title ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                )),
        backgroundColor: Colors.transparent,
        centerTitle: centerTitle,
        elevation: 0,
        bottom: appBarBottom != null ? ResponsiveAppBarBottom(child: appBarBottom!) : null,
        actions: [
          if (appBarActions != null) ...appBarActions!,
          if (showAvatar) _buildAvatar(context, user),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: LiquidBackground()),
          // Status bar glow accent
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top + 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.indigo.withValues(alpha: isDark ? 0.15 : 0.05),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final maxContentWidth = isWide ? 800.0 : constraints.maxWidth;
              // Extremely tight padding for absolute minimal gap
              final topPadding = MediaQuery.of(context).padding.top + 18.0;

              Widget content;
              if (body != null) {
                content = Padding(
                  padding: (padding as EdgeInsets?)?.copyWith(top: (padding as EdgeInsets?)?.top ?? topPadding) 
                            ?? EdgeInsets.fromLTRB(16, topPadding, 16, 16),
                  child: body!,
                );
              } else {
                content = ListView(
                  padding: (padding as EdgeInsets?)?.copyWith(
                            top: (padding as EdgeInsets?)?.top ?? topPadding,
                            bottom: (padding as EdgeInsets?)?.bottom ?? 100,
                          ) ??
                      EdgeInsets.fromLTRB(16, topPadding, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  children: children,
                );
              }

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: maxContentWidth,
                  child: content,
                ),
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
          child: GlassContainer(
            width: 36,
            height: 36,
            padding: EdgeInsets.zero,
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

    final avatarUrl = user?.photoURL;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassContainer(
          width: 400,
          padding: const EdgeInsets.all(32),
          gradientColors: isDark 
            ? [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.05)]
            : [Colors.white.withValues(alpha: 0.9), Colors.white.withValues(alpha: 0.7)],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Larger Avatar in Modal
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: avatarUrl != null
                      ? Image.network(avatarUrl, fit: BoxFit.cover)
                      : _buildDefaultAvatar(user),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                user?.displayName ?? s.unknownMember,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                user?.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  showMyProfile(context);
                },
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
                label: Text(s.myPaymentDetails),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        s.cancel,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black45,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AppState>().signOut();
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        s.logout,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

class ResponsiveAppBarBottom extends StatelessWidget
    implements PreferredSizeWidget {
  final PreferredSizeWidget child;

  const ResponsiveAppBarBottom({super.key, required this.child});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: child,
      ),
    );
  }
}
