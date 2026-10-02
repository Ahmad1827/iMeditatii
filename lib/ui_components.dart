import 'package:flutter/material.dart';
import 'theme_manager.dart';
import 'app_colors.dart';

// ---------------------------------------------------------------------------
// 1. DESIGN STRATEGY CONTRACT
// ---------------------------------------------------------------------------
abstract class StyleStrategy {
  BorderRadius get cardRadius;
  BorderRadius get buttonRadius;
  
  BoxDecoration cardDecoration({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required double shadowOffset,
  });

  BoxDecoration buttonDecoration({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required bool isPressed,
    required bool isHovered,
  });

  Matrix4 buttonTransform({
    required bool isPressed,
    required bool isHovered,
  });

  TextStyle buttonTextStyle({
    required Color textColor,
    required double fontSize,
  });
}

// ---------------------------------------------------------------------------
// 2. CONCRETE STRATEGY A: 8-BIT RETRO (CURRENT NEU-BRUTALIST STYLE)
// ---------------------------------------------------------------------------
class RetroStyleStrategy implements StyleStrategy {
  @override
  BorderRadius get cardRadius => BorderRadius.zero;

  @override
  BorderRadius get buttonRadius => BorderRadius.zero;

  @override
  BoxDecoration cardDecoration({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required double shadowOffset,
  }) {
    return BoxDecoration(
      color: bgColor,
      border: Border.all(color: borderColor, width: 3),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: Offset(shadowOffset, shadowOffset),
          blurRadius: 0,
        ),
      ],
    );
  }

  @override
  BoxDecoration buttonDecoration({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required bool isPressed,
    required bool isHovered,
  }) {
    return BoxDecoration(
      color: bgColor,
      border: Border.all(color: borderColor, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: isPressed ? const Offset(0, 0) : const Offset(4, 4),
          blurRadius: 0,
        ),
      ],
    );
  }

  @override
  Matrix4 buttonTransform({required bool isPressed, required bool isHovered}) {
    final offset = isPressed ? 3.0 : (isHovered ? -1.5 : 0.0);
    return Matrix4.translationValues(offset, offset, 0);
  }

  @override
  TextStyle buttonTextStyle({required Color textColor, required double fontSize}) {
    return TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.0,
    );
  }
}

// ---------------------------------------------------------------------------
// 3. CONCRETE STRATEGY B: CLEAN / MINIMAL (PBINFO-LIKE ACADEMIC STYLE)
// ---------------------------------------------------------------------------
class CleanStyleStrategy implements StyleStrategy {
  @override
  BorderRadius get cardRadius => BorderRadius.circular(10);

  @override
  BorderRadius get buttonRadius => BorderRadius.circular(8);

  @override
  BoxDecoration cardDecoration({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required double shadowOffset,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: cardRadius,
      border: Border.all(
        color: AppColors.isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.07),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(AppColors.isDark ? 0.35 : 0.05),
          offset: const Offset(0, 3),
          blurRadius: 10,
        ),
      ],
    );
  }

  @override
  BoxDecoration buttonDecoration({
    required Color bgColor,
    required Color borderColor,
    required Color shadowColor,
    required bool isPressed,
    required bool isHovered,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: buttonRadius,
      border: Border.all(
        color: Colors.white.withOpacity(0.12),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: bgColor.withOpacity(isHovered ? 0.4 : 0.25),
          offset: Offset(0, isPressed ? 1 : (isHovered ? 4 : 2)),
          blurRadius: isPressed ? 2 : (isHovered ? 10 : 5),
        ),
      ],
    );
  }

  @override
  Matrix4 buttonTransform({required bool isPressed, required bool isHovered}) {
    final scale = isPressed ? 0.98 : (isHovered ? 1.02 : 1.0);
    return Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  @override
  TextStyle buttonTextStyle({required Color textColor, required double fontSize}) {
    return TextStyle(
      color: textColor,
      fontSize: fontSize - 1.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    );
  }
}

// ---------------------------------------------------------------------------
// 4. STRATEGY FACTORY
// ---------------------------------------------------------------------------
class StyleStrategyFactory {
  static final StyleStrategy _retro = RetroStyleStrategy();
  static final StyleStrategy _clean = CleanStyleStrategy();

  static StyleStrategy get current => 
      ThemeManager.styleNotifier.value == AppStyleMode.retro ? _retro : _clean;
}

// ---------------------------------------------------------------------------
// 5. GLOBAL UI ADAPTERS (Drop-in replacements for all screens)
// ---------------------------------------------------------------------------
class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final double padding;
  final double shadowOffset;
  final Color? borderColor;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppStyleMode>(
      valueListenable: ThemeManager.styleNotifier,
      builder: (context, _, __) {
        final strategy = StyleStrategyFactory.current;
        final effectiveBg = bgColor ?? AppColors.cardBg;
        final effectiveBorder = borderColor ?? AppColors.border;

        return Container(
          decoration: strategy.cardDecoration(
            bgColor: effectiveBg,
            borderColor: effectiveBorder,
            shadowColor: AppColors.shadow,
            shadowOffset: shadowOffset,
          ),
          padding: EdgeInsets.all(padding),
          child: child,
        );
      },
    );
  }
}

class RetroButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? bgColor;
  final Color? textColor;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;
  final double fontSize;
  final EdgeInsets padding;

  const RetroButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.bgColor,
    this.textColor,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
    this.fontSize = 15,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool isPressed = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppStyleMode>(
      valueListenable: ThemeManager.styleNotifier,
      builder: (context, _, __) {
        final strategy = StyleStrategyFactory.current;
        final effectiveBg = widget.bgColor ?? AppColors.sunset;
        final effectiveTextColor = widget.textColor ?? Colors.white;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: GestureDetector(
            onTapDown: widget.isLoading ? null : (_) => setState(() => isPressed = true),
            onTapUp: widget.isLoading
                ? null
                : (_) {
                    setState(() => isPressed = false);
                    widget.onPressed();
                  },
            onTapCancel: () => setState(() => isPressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.isFullWidth ? double.infinity : null,
              transform: strategy.buttonTransform(isPressed: isPressed, isHovered: isHovered),
              transformAlignment: Alignment.center,
              decoration: strategy.buttonDecoration(
                bgColor: widget.isLoading ? Colors.grey : effectiveBg,
                borderColor: AppColors.border,
                shadowColor: AppColors.shadow,
                isPressed: isPressed,
                isHovered: isHovered,
              ),
              padding: widget.padding,
              child: widget.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: effectiveTextColor, size: widget.fontSize + 2),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: strategy.buttonTextStyle(
                            textColor: effectiveTextColor,
                            fontSize: widget.fontSize,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}