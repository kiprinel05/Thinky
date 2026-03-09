import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thinky/shared_controls/theme/app_colors.dart';
import 'package:thinky/core_controls/routing/route_names.dart';

/// MainShellPage — wraps the main app pages with a floating, pill-shaped
/// bottom navigation island inspired by iOS Dynamic Island.
class MainShellPage extends StatefulWidget {
  final Widget child;

  const MainShellPage({super.key, required this.child});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage>
    with TickerProviderStateMixin {
  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconAnimations;
  bool _isAtTop = true;

  static const _tabs = [
    RouteNames.missions,
    RouteNames.workshop,
    RouteNames.profile,
  ];

  static const _icons = [
    Icons.rocket_launch_rounded,
    Icons.extension_rounded,
    Icons.person_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _tabs.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _iconAnimations = _iconControllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.25)
              .chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 45,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.25, end: 0.95)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 25,
        ),
      ]).animate(controller);
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _iconControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    return index < 0 ? 0 : index;
  }

  void _onTabTapped(int index) {
    final current = _currentIndex(context);
    if (index == current) return;
    _iconControllers[index].forward(from: 0.0);
    context.go(_tabs[index]);
  }

  bool _handleScroll(ScrollNotification notification) {
    final atTop = notification.metrics.pixels < 60;
    if (atTop != _isAtTop) {
      setState(() => _isAtTop = atTop);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _currentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: Stack(
          children: [
            // Page content fills the entire screen
            Positioned.fill(child: widget.child),

            // Gradient fade above nav — visible at top, fades out on scroll
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isAtTop ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: Container(
                    height: bottomPadding + 120,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xB3FFFFFF),
                          Color(0x80FFFFFF),
                          Color(0x33FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating nav island — positioned at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding + 8,
              child: Center(
                child: _buildNavIsland(selectedIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIsland(int selectedIndex) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Full-width shadow layer — spans the entire page width
          Positioned(
            left: 20,
            right: 20,
            bottom: -6,
            child: Container(
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.08),
                    blurRadius: 40,
                    spreadRadius: 8,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            ),
          ),
          // The island pill
          Container(
            height: 54,
            width: 200,
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_tabs.length, (index) {
                return _buildNavItem(
                  index: index,
                  selectedIndex: selectedIndex,
                  icon: _icons[index],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int selectedIndex,
    required IconData icon,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _iconAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _iconAnimations[index].value,
            child: child,
          );
        },
        child: SizedBox(
          width: 48,
          height: 52,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryPurple.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: isSelected ? 22 : 20,
                color: isSelected
                    ? AppColors.primaryPurple
                    : AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
