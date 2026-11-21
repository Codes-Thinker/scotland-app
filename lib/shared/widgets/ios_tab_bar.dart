import 'dart:ui';

import 'package:flutter/material.dart';

class IosTabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;

  const IosTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });
}

/// Floating pill tab bar — WhatsApp iOS style (glass + selected capsule).
class IosTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<IosTabItem> items;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final bool showLabels;

  const IosTabBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTap,
    required this.activeColor,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 8 + bottom.clamp(0, 18)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                height: showLabels ? 62 : 54,
                decoration: BoxDecoration(
                  color: const Color(0xE8F2F2F7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _TabButton(
                          item: items[i],
                          selected: i == selectedIndex,
                          activeColor: activeColor,
                          showLabel: showLabels,
                          compact: items.length > 5,
                          onTap: () => onTap(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatefulWidget {
  final IosTabItem item;
  final bool selected;
  final Color activeColor;
  final bool showLabel;
  final bool compact;
  final VoidCallback onTap;

  const _TabButton({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.showLabel,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? widget.activeColor : const Color(0xFF8E8E93);
    final iconSize = widget.compact ? 22.0 : 24.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.selected ? Colors.white.withValues(alpha: 0.72) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.selected ? widget.item.activeIcon : widget.item.icon,
                    size: iconSize,
                    color: color,
                  ),
                  if ((widget.item.badge ?? 0) > 0)
                    Positioned(
                      right: -9,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.activeColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          '${widget.item.badge}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.showLabel) ...[
                const SizedBox(height: 2),
                Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.compact ? 9 : 10,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.2,
                    height: 1.05,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
