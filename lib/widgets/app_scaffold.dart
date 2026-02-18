import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_holidays/theme/app_colors.dart';
import 'package:my_holidays/theme/app_gradients.dart';
import 'package:my_holidays/theme/app_text_styles.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title = '',
    this.subtitle,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.onBack,
    this.headerBottom,
    this.showMenuButton = true,
    this.centerTitle = false,
    this.isHome = false,
    this.showHolidayIcon = true,
    this.useOverlayNav = false,
    this.overlayFabIcon,
    this.overlayFabOnPressed,
  });

  final String title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? headerBottom;
  final bool showMenuButton;
  final bool centerTitle;
  final bool isHome;
  final bool showHolidayIcon;
  final bool useOverlayNav;
  final IconData? overlayFabIcon;
  final VoidCallback? overlayFabOnPressed;

  @override
  Widget build(BuildContext context) {
    if (useOverlayNav) return _buildOverlayLayout(context);
    return _buildClassicLayout(context);
  }

  // --- Overlay nav: no header bar, floating buttons over content ---

  Widget _buildOverlayLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  _overlayButton(
                    onPressed: () => context.go('/'),
                    icon: Icons.home_rounded,
                    tooltip: 'Home',
                  ),
                  Expanded(
                    child: title.isNotEmpty
                        ? Text(
                            title,
                            style: AppTextStyles.subheading.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (actions != null)
                    ...actions!.map((a) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: a,
                        )),
                  if (showMenuButton)
                    const _OverlayMenuButton()
                  else
                    const SizedBox(width: 42),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: _buildOverlayFabs(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget? _buildOverlayFabs(BuildContext context) {
    final backButton = showBackButton
        ? _overlayButton(
            onPressed: onBack ??
                () {
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
          )
        : null;

    final actionButton = overlayFabIcon != null && overlayFabOnPressed != null
        ? _overlayButton(
            onPressed: overlayFabOnPressed!,
            icon: overlayFabIcon!,
            tooltip: 'Action',
          )
        : null;

    if (backButton != null || actionButton != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            backButton ?? const SizedBox(width: 42),
            actionButton ?? const SizedBox(width: 42),
          ],
        ),
      );
    }
    return null;
  }

  static Widget _overlayButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.white, size: 22),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }

  // --- Classic layout: gradient header bar ---

  Widget _buildClassicLayout(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppGradients.header,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _buildHomeIcon(context),
                        if (showBackButton && !isHome) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: onBack ??
                                () {
                                  if (GoRouter.of(context).canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/');
                                  }
                                },
                          ),
                        ],
                        const SizedBox(width: 8),
                        Expanded(
                          child: titleWidget ??
                              Row(
                                mainAxisAlignment: centerTitle
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: centerTitle
                                          ? CrossAxisAlignment.center
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: AppTextStyles.heading
                                              .copyWith(color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (subtitle != null)
                                          Text(
                                            subtitle!,
                                            style: AppTextStyles.caption
                                                .copyWith(color: Colors.white70),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (showHolidayIcon) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 64,
                                      height: 64,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.asset(
                                        'assets/images/holiday-icon.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                        ),
                        if (actions != null) ...actions!,
                        if (showMenuButton) const _ClassicMenuButton(),
                      ],
                    ),
                    if (headerBottom != null) ...[
                      const SizedBox(height: 12),
                      headerBottom!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildHomeIcon(BuildContext context) {
    if (isHome) {
      return const Icon(Icons.home_rounded, color: Colors.white, size: 28);
    }
    return IconButton(
      icon: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
      onPressed: () => context.go('/'),
      tooltip: 'Home',
    );
  }
}

/// "..." menu button styled as a purple circle for overlay nav.
class _OverlayMenuButton extends StatelessWidget {
  const _OverlayMenuButton();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 22),
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (path) => context.go(path),
        itemBuilder: (_) => [
          _menuItem('/settings', 'Settings & Tools', Icons.settings_rounded, location),
          _menuItem('/about', 'About', Icons.info_outline_rounded, location),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String path, String label, IconData icon, String location) {
    final isCurrent =
        path == '/' ? location == '/' : location.startsWith(path);
    return PopupMenuItem<String>(
      value: path,
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

/// Hamburger menu for classic header layout.
class _ClassicMenuButton extends StatelessWidget {
  const _ClassicMenuButton();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu_rounded, color: Colors.white),
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (path) => context.go(path),
      itemBuilder: (_) => [
        _menuItem('/settings', 'Settings & Tools', Icons.settings_rounded, location),
        _menuItem('/about', 'About', Icons.info_outline_rounded, location),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(
      String path, String label, IconData icon, String location) {
    final isCurrent =
        path == '/' ? location == '/' : location.startsWith(path);
    return PopupMenuItem<String>(
      value: path,
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
