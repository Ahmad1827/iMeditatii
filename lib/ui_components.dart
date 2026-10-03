import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'design_system.dart';
import 'theme_manager.dart';

export 'design_system.dart';

// =============================================================================
// STYLE BUILDER — rebuilds on Light/Dark AND Retro/Clean.
// =============================================================================
class StyleBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppStyle s) builder;
  const StyleBuilder({super.key, required this.builder});

  static final Listenable _changes =
      Listenable.merge([ThemeManager.themeNotifier, ThemeManager.styleNotifier]);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _changes,
      builder: (context, _) => builder(context, AppStyle.of(context)),
    );
  }
}

// =============================================================================
// RETRO BLOCK / RETRO BUTTON
// Retro: original neu-brutalist look. Clean: Bootstrap card / button.
// Screens you haven't converted yet still get the Clean look through these.
// =============================================================================
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
    return StyleBuilder(
      builder: (context, s) {
        final requested = bgColor ?? AppColors.cardBg;
        if (s.isClean) {
          final neutral = requested == AppColors.cardBg ||
              requested == AppColors.cloud ||
              requested == AppColors.mustard ||
              requested == AppColors.bg ||
              requested == AppColors.headerBg;
          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: neutral ? Pb.surface : requested,
              borderRadius: Pb.radius,
              border: Border.all(color: Pb.border),
            ),
            child: child,
          );
        }
        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: requested,
            border: Border.all(color: borderColor ?? AppColors.border, width: 3),
            boxShadow: AppStyle.hardShadow(shadowOffset),
          ),
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
    return StyleBuilder(
      builder: (context, s) {
        if (s.isClean) {
          return PbButton(
            text: AppStyle.sentence(widget.text),
            onPressed: widget.onPressed,
            variant: pbVariantFromRetro(widget.bgColor),
            icon: widget.icon,
            fullWidth: widget.isFullWidth,
            loading: widget.isLoading,
            size: widget.fontSize <= 14 ? PbSize.sm : PbSize.md,
          );
        }

        final effectiveBg = widget.bgColor ?? AppColors.sunset;
        final effectiveTextColor = widget.textColor ?? Colors.white;
        final offset = isPressed ? 3.0 : (isHovered ? -1.5 : 0.0);

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
              transform: Matrix4.translationValues(offset, offset, 0),
              decoration: BoxDecoration(
                color: widget.isLoading ? Colors.grey : effectiveBg,
                border: Border.all(color: AppColors.border, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: isPressed ? Offset.zero : const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
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
                          style: TextStyle(
                            color: effectiveTextColor,
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
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

// =============================================================================
// ============================  CLEAN (Pb) KIT  ===============================
// =============================================================================

/// Centered page container (Bootstrap .container).
class PbContainer extends StatelessWidget {
  final Widget child;
  const PbContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width < 600 ? 12.0 : 24.0;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Pb.containerMax),
        child: Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: child),
      ),
    );
  }
}

// ----------------------------------------------------------------- BUTTON
enum PbVariant {
  primary,
  secondary,
  success,
  danger,
  dark,
  light,
  outlinePrimary,
  outlineSecondary,
  outlineDanger,
  outlineLight,
  link,
}

enum PbSize { sm, md, lg }

/// Maps the retro accent colors used across old screens to Bootstrap variants.
PbVariant pbVariantFromRetro(Color? c) {
  if (c == null) return PbVariant.primary;
  if (c == AppColors.forest) return PbVariant.success;
  if (c == AppColors.ink) return PbVariant.dark;
  if (c == AppColors.mustard || c == AppColors.cardBg || c == AppColors.cloud || c == AppColors.bg) {
    return PbVariant.outlineSecondary;
  }
  return PbVariant.primary;
}

class _BtnColors {
  final Color bg;
  final Color fg;
  final Color border;
  const _BtnColors(this.bg, this.fg, this.border);
}

_BtnColors _btnColors(PbVariant v, bool hover, bool down) {
  final dark = AppColors.isDark;
  Color shade(Color base, Color h, Color d) => down ? d : (hover ? h : base);
  final active = hover || down;

  switch (v) {
    case PbVariant.primary:
      final c = shade(Pb.primary, const Color(0xFF0B6870), const Color(0xFF095A61));
      return _BtnColors(c, Colors.white, c);
    case PbVariant.secondary:
      final c = shade(Pb.secondary, const Color(0xFF5C636A), const Color(0xFF565E64));
      return _BtnColors(c, Colors.white, c);
    case PbVariant.success:
      final c = shade(Pb.success, const Color(0xFF157347), const Color(0xFF146C43));
      return _BtnColors(c, Colors.white, c);
    case PbVariant.danger:
      final c = shade(Pb.danger, const Color(0xFFBB2D3B), const Color(0xFFB02A37));
      return _BtnColors(c, Colors.white, c);
    case PbVariant.dark:
      if (dark) {
        final c = shade(const Color(0xFFF8F9FA), const Color(0xFFD3D4D5), const Color(0xFFC6C7C8));
        return _BtnColors(c, Colors.black, c);
      }
      final c = shade(const Color(0xFF212529), const Color(0xFF424649), const Color(0xFF373B3E));
      return _BtnColors(c, Colors.white, c);
    case PbVariant.light:
      final c = shade(const Color(0xFFF8F9FA), const Color(0xFFD3D4D5), const Color(0xFFC6C7C8));
      return _BtnColors(c, Colors.black, c);
    case PbVariant.outlinePrimary:
      return active
          ? const _BtnColors(Pb.primary, Colors.white, Pb.primary)
          : _BtnColors(Colors.transparent, Pb.link, Pb.link);
    case PbVariant.outlineSecondary:
      final base = dark ? const Color(0xFFADB5BD) : Pb.secondary;
      return active
          ? const _BtnColors(Pb.secondary, Colors.white, Pb.secondary)
          : _BtnColors(Colors.transparent, base, base);
    case PbVariant.outlineDanger:
      final base = dark ? const Color(0xFFEA868F) : Pb.danger;
      return active
          ? const _BtnColors(Pb.danger, Colors.white, Pb.danger)
          : _BtnColors(Colors.transparent, base, base);
    case PbVariant.outlineLight:
      return active
          ? const _BtnColors(Color(0xFFF8F9FA), Color(0xFF212529), Color(0xFFF8F9FA))
          : const _BtnColors(Colors.transparent, Colors.white, Colors.white);
    case PbVariant.link:
      return _BtnColors(Colors.transparent, Pb.link, Colors.transparent);
  }
}

class PbButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final PbVariant variant;
  final PbSize size;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const PbButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = PbVariant.primary,
    this.size = PbSize.md,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  State<PbButton> createState() => _PbButtonState();
}

class _PbButtonState extends State<PbButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    final disabled = widget.onPressed == null || widget.loading;
    final c = _btnColors(widget.variant, _hover && !disabled, _down && !disabled);

    final double fs = widget.size == PbSize.sm ? 14 : (widget.size == PbSize.lg ? 18 : 16);
    final EdgeInsets pad = widget.size == PbSize.sm
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
        : (widget.size == PbSize.lg
            ? const EdgeInsets.symmetric(horizontal: 18, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 8));

    final label = Text(
      widget.text,
      style: TextStyle(
        fontSize: fs,
        color: c.fg,
        height: 1.25,
        decoration: widget.variant == PbVariant.link && _hover ? TextDecoration.underline : null,
      ),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading) ...[
          SizedBox(width: fs - 2, height: fs - 2, child: CircularProgressIndicator(strokeWidth: 2, color: c.fg)),
          const SizedBox(width: 8),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: fs + 1, color: c.fg),
          const SizedBox(width: 6),
        ],
        label,
      ],
    );

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _down = true),
        onTapUp: disabled
            ? null
            : (_) {
                setState(() => _down = false);
                widget.onPressed!();
              },
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.fullWidth ? double.infinity : null,
          alignment: widget.fullWidth ? Alignment.center : null,
          padding: pad,
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: Pb.radius,
            border: Border.all(color: c.border),
          ),
          child: Opacity(opacity: widget.onPressed == null ? 0.65 : 1, child: content),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- LINK
class PbLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final double fontSize;
  final bool underline;
  final FontWeight? weight;

  const PbLink({
    super.key,
    required this.text,
    required this.onTap,
    this.fontSize = 16,
    this.underline = false,
    this.weight,
  });

  @override
  State<PbLink> createState() => _PbLinkState();
}

class _PbLinkState extends State<PbLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.fontSize,
            color: Pb.link,
            fontWeight: widget.weight,
            decoration: (widget.underline || _hover) ? TextDecoration.underline : null,
            decorationColor: Pb.link,
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- CARD
class PbCard extends StatelessWidget {
  final String? title;
  final Widget? header;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const PbCard({
    super.key,
    this.title,
    this.header,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    final head = header ??
        (title != null ? Text(title!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Pb.text, height: 1.3)) : null);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Pb.surface,
        borderRadius: Pb.radius,
        border: Border.all(color: Pb.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (head != null) ...[
            Container(
              color: Pb.cardHeader,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: head,
            ),
            Container(height: 1, color: Pb.border),
          ],
          Padding(padding: padding, child: child),
          if (footer != null) ...[
            Container(height: 1, color: Pb.border),
            Container(
              color: Pb.cardHeader,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: footer,
            ),
          ],
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- BADGE
class PbBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color textColor;
  final double fontSize;

  const PbBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor = Colors.white,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.32),
      decoration: BoxDecoration(color: color ?? Pb.secondary, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w700, height: 1.15),
      ),
    );
  }
}

// ----------------------------------------------------------------- ALERT
enum PbAlertType { info, secondary, success, danger, warning }

class PbAlert extends StatelessWidget {
  final PbAlertType type;
  final String? text;
  final Widget? child;
  final IconData? icon;

  const PbAlert({super.key, this.type = PbAlertType.secondary, this.text, this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    late Color bg, fg, bd;
    switch (type) {
      case PbAlertType.info:
        bg = Pb.infoBg; fg = Pb.infoText; bd = Pb.infoBorder;
        break;
      case PbAlertType.secondary:
        bg = Pb.secondaryBg; fg = Pb.secondaryText; bd = Pb.secondaryBorder;
        break;
      case PbAlertType.success:
        bg = Pb.successBg; fg = Pb.successText; bd = Pb.successBorder;
        break;
      case PbAlertType.danger:
        bg = Pb.dangerBg; fg = Pb.dangerText; bd = Pb.dangerBorder;
        break;
      case PbAlertType.warning:
        bg = Pb.warningBg; fg = Pb.warningText; bd = Pb.warningBorder;
        break;
    }

    final content = DefaultTextStyle.merge(
      style: TextStyle(color: fg, fontSize: 16, height: 1.5),
      child: child ?? Text(text ?? ''),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: bg, borderRadius: Pb.radius, border: Border.all(color: bd)),
      child: icon == null
          ? content
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 20, color: fg)),
                const SizedBox(width: 10),
                Expanded(child: content),
              ],
            ),
    );
  }
}

// ----------------------------------------------------------------- NAV TABS
class PbNavTabs extends StatelessWidget {
  final List<String> labels;
  final List<String?>? badges;
  final int selected;
  final ValueChanged<int> onSelect;

  const PbNavTabs({super.key, required this.labels, required this.selected, required this.onSelect, this.badges});

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < labels.length; i++)
          _PbTab(
            label: labels[i],
            badge: badges != null && i < badges!.length ? badges![i] : null,
            active: i == selected,
            onTap: () => onSelect(i),
          ),
        Expanded(child: Container(height: 1, color: Pb.border)),
      ],
    );
  }
}

class _PbTab extends StatefulWidget {
  final String label;
  final String? badge;
  final bool active;
  final VoidCallback onTap;

  const _PbTab({required this.label, required this.badge, required this.active, required this.onTap});

  @override
  State<_PbTab> createState() => _PbTabState();
}

class _PbTabState extends State<_PbTab> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: Pb.border);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            color: widget.active ? Pb.text : Pb.muted,
            fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400,
            decoration: !widget.active && _hover ? TextDecoration.underline : null,
            decorationColor: Pb.link,
          ),
        ),
        if (widget.badge != null) ...[
          const SizedBox(width: 6),
          PbBadge(text: widget.badge!, fontSize: 11.5),
        ],
      ],
    );

    return MouseRegion(
      cursor: widget.active ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            border: Border(bottom: widget.active ? const BorderSide(color: Pb.primary, width: 2) : side),
          ),
          child: row,
        ),
      ),
    );
  }
}

/// Body under [PbNavTabs] (no top border, joins the active tab).
class PbTabPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const PbTabPanel({super.key, required this.child, this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 20)});

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: Pb.border);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Pb.surface,
        border: Border(left: side, right: side, bottom: side),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
      ),
      child: child,
    );
  }
}

// ----------------------------------------------------------------- BREADCRUMB
class PbCrumb {
  final String label;
  final VoidCallback? onTap;
  const PbCrumb(this.label, [this.onTap]);
}

class PbBreadcrumb extends StatelessWidget {
  final List<PbCrumb> items;
  const PbBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(color: Pb.muted, fontSize: 16)),
            ),
          if (items[i].onTap != null && i < items.length - 1)
            PbLink(text: items[i].label, onTap: items[i].onTap!, fontSize: 14)
          else
            Text(items[i].label, style: TextStyle(color: Pb.muted, fontSize: 16)),
        ],
      ],
    );
  }
}

// ----------------------------------------------------------------- TABLE
class PbTable extends StatelessWidget {
  final List<String>? headers;
  final List<List<Widget>> rows;
  final List<Color?>? rowColors;
  final Map<int, TableColumnWidth>? columnWidths;
  final bool striped;
  final bool firstColumnBold;

  const PbTable({
    super.key,
    this.headers,
    required this.rows,
    this.rowColors,
    this.columnWidths,
    this.striped = false,
    this.firstColumnBold = false,
  });

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);

    Widget cell(Widget w, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: Pb.text,
              fontSize: 15.5,
              height: 1.4,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
            child: w,
          ),
        );

    return Table(
      border: TableBorder.all(color: Pb.border),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        if (headers != null)
          TableRow(
            decoration: BoxDecoration(color: Pb.surface),
            children: [for (final h in headers!) cell(Text(h), bold: true)],
          ),
        for (var r = 0; r < rows.length; r++)
          TableRow(
            decoration: BoxDecoration(
              color: rowColors?[r] ?? (striped && r.isOdd ? Pb.tableStripe : Pb.surface),
            ),
            children: [
              for (var c = 0; c < rows[r].length; c++) cell(rows[r][c], bold: firstColumnBold && c == 0),
            ],
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- TEXT
/// Orange statement heading (pbinfo "Cerința", "Exemplu").
class PbHeading extends StatelessWidget {
  final String text;
  final double size;
  final EdgeInsets padding;

  const PbHeading(this.text, {super.key, this.size = 17, this.padding = const EdgeInsets.only(top: 20, bottom: 6)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(text, style: TextStyle(fontSize: size, color: Pb.heading, fontWeight: FontWeight.w700, height: 1.2)),
    );
  }
}

/// Body text; `backticks` become pink inline code.
class PbRichText extends StatelessWidget {
  final String text;
  final double fontSize;
  final double height;
  final Color? color;

  const PbRichText(this.text, {super.key, this.fontSize = 16.5, this.height = 1.65, this.color});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: fontSize, height: height, color: color ?? Pb.text);
    final parts = text.split('`');
    return SelectableText.rich(
      TextSpan(
        style: base,
        children: [
          for (var i = 0; i < parts.length; i++)
            if (parts[i].isNotEmpty)
              TextSpan(
                text: parts[i],
                style: i.isOdd ? Pb.mono(fontSize * 0.88, color: Pb.inlineCode, height: height).copyWith(backgroundColor: Pb.codeChip) : null,
              ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- CODE
class PbCodeBox extends StatelessWidget {
  final String code;
  final String? lang; // null = plain text (test data)
  final double fontSize;

  const PbCodeBox(this.code, {super.key, this.lang, this.fontSize = 15});

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    final style = Pb.mono(fontSize);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Pb.codeBg, borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
      child: SelectableText.rich(
        lang == null
            ? TextSpan(text: code.isEmpty ? ' ' : code, style: style)
            : CodeHighlighter.span(code, style, lang: lang!),
      ),
    );
  }
}

class PbCodeBlock extends StatelessWidget {
  final String code;
  final String lang;
  final VoidCallback onCopy;

  const PbCodeBlock({super.key, required this.code, required this.lang, required this.onCopy});

  static const Map<String, String> _labels = {'cpp': 'C++', 'python': 'Python'};

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Pb.cardHeader,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(_labels[lang] ?? lang, style: TextStyle(fontSize: 14, color: Pb.muted, fontWeight: FontWeight.w700)),
                const Spacer(),
                PbButton(
                  text: 'Copiază',
                  icon: Icons.content_copy,
                  variant: PbVariant.outlineSecondary,
                  size: PbSize.sm,
                  onPressed: onCopy,
                ),
              ],
            ),
          ),
          Container(height: 1, color: Pb.border),
          Container(
            color: Pb.codeBg,
            padding: const EdgeInsets.all(14),
            child: SelectableText.rich(CodeHighlighter.span(code, Pb.mono(14.5), lang: lang)),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- LIST GROUP
class PbListItem {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? trailing;
  const PbListItem(this.label, {this.onTap, this.icon, this.trailing});
}

class PbListGroup extends StatelessWidget {
  final List<PbListItem> items;
  final bool flush; // inside a card: no outer border

  const PbListGroup({super.key, required this.items, this.flush = false});

  @override
  Widget build(BuildContext context) {
    AppStyle.of(context);
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) Container(height: 1, color: Pb.border),
          _PbListTile(item: items[i]),
        ],
      ],
    );
    if (flush) return list;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: Pb.surface, borderRadius: Pb.radius, border: Border.all(color: Pb.border)),
      child: list,
    );
  }
}

class _PbListTile extends StatefulWidget {
  final PbListItem item;
  const _PbListTile({required this.item});

  @override
  State<_PbListTile> createState() => _PbListTileState();
}

class _PbListTileState extends State<_PbListTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tappable = item.onTap != null;
    return MouseRegion(
      cursor: tappable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: item.onTap,
        child: Container(
          color: tappable && _hover ? Pb.hoverBg : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 18, color: Pb.muted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(fontSize: 16, color: tappable ? Pb.link : Pb.text, height: 1.35),
                ),
              ),
              if (item.trailing != null) PbBadge(text: item.trailing!, color: Pb.primary, fontSize: 11.5),
              if (tappable) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 18, color: Pb.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- PROGRESS
class PbProgress extends StatelessWidget {
  final double value;
  final String? label;

  const PbProgress({super.key, required this.value, this.label});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: Pb.radius,
      child: Container(
        height: 18,
        color: Pb.gray,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: Container(
              color: Pb.primary,
              alignment: Alignment.center,
              child: (label != null && v >= 0.2)
                  ? Text(label!, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- MODAL
Future<T?> showPbModal<T>(
  BuildContext context, {
  required String title,
  required Widget body,
  required List<Widget> Function(BuildContext dialogContext) actions,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Pb.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: Pb.radius, side: BorderSide(color: Pb.border)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: TextStyle(fontSize: 20, color: Pb.text))),
                  IconButton(icon: Icon(Icons.close, color: Pb.muted), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
            Container(height: 1, color: Pb.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: DefaultTextStyle.merge(style: TextStyle(color: Pb.text, fontSize: 16, height: 1.5), child: body),
            ),
            Container(height: 1, color: Pb.border),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions(ctx)),
            ),
          ],
        ),
      ),
    ),
  );
}

// =============================================================================
// CODE HIGHLIGHTER — shared by the editor and lecture snippets.
// Palette follows the style: Retro neon / Clean light (GitHub) / Clean dark.
// =============================================================================
class _CodePalette {
  final Color text, comment, string, preproc, type, keyword, number, bracket, op;
  final bool bold;
  const _CodePalette({
    required this.text,
    required this.comment,
    required this.string,
    required this.preproc,
    required this.type,
    required this.keyword,
    required this.number,
    required this.bracket,
    required this.op,
    this.bold = false,
  });
}

class CodeHighlighter {
  static final RegExp _cpp = RegExp(
    r'(//[^\n]*)' // 1 comment
    r'|("(\\"|[^"])*")' // 2 string
    r'|(#[a-zA-Z]+)' // 4 preprocessor
    r'|(\b(int|long|float|double|char|bool|void|string|vector|set|map|pair|stack|queue|struct|class|auto|const|unsigned)\b)' // 5 type
    r'|(\b(cin|cout|endl|return|if|else|while|for|do|break|continue|switch|case|default|using|namespace|std|main|true|false)\b)' // 7 keyword
    r'|(\b\d+\b)' // 9 number
    r'|([{}()\[\]])' // 10 bracket
    r'|([+\-*/%=<>!&|]+)', // 11 operator
  );

  static final RegExp _py = RegExp(
    r'(#[^\n]*)' // 1 comment
    r'''|("[^"\n]*"|'[^'\n]*')''' // 2 string
    r'|(\b(int|float|str|bool|list|dict|set|tuple)\b)' // 3 type
    r'|(\b(def|return|if|elif|else|while|for|in|break|continue|import|from|as|and|or|not|print|input|range|len|True|False|None|lambda|pass|class)\b)' // 5 keyword
    r'|(\b\d+(\.\d+)?\b)' // 7 number
    r'|([{}()\[\]])' // 9 bracket
    r'|([+\-*/%=<>!&|]+)', // 10 operator
  );

  static _CodePalette _palette() {
    final s = AppStyle.current;
    if (s.isRetro) {
      return const _CodePalette(
        text: Color(0xFFECEFF4),
        comment: Color(0xFF7F8C8D),
        string: Color(0xFFF9CA24),
        preproc: Color(0xFFFF7675),
        type: Color(0xFF55EFC4),
        keyword: Color(0xFF74B9FF),
        number: Color(0xFFFAB1A0),
        bracket: Color(0xFFFDCB6E),
        op: Color(0xFFFF7675),
        bold: true,
      );
    }
    if (s.isDark) {
      return const _CodePalette(
        text: Color(0xFFD4D4D4),
        comment: Color(0xFF6A9955),
        string: Color(0xFFCE9178),
        preproc: Color(0xFFC586C0),
        type: Color(0xFF4EC9B0),
        keyword: Color(0xFF569CD6),
        number: Color(0xFFB5CEA8),
        bracket: Color(0xFFD4D4D4),
        op: Color(0xFFD4D4D4),
      );
    }
    return const _CodePalette(
      text: Color(0xFF24292F),
      comment: Color(0xFF6A737D),
      string: Color(0xFF0A3069),
      preproc: Color(0xFFCF222E),
      type: Color(0xFF8250DF),
      keyword: Color(0xFFCF222E),
      number: Color(0xFF0550AE),
      bracket: Color(0xFF24292F),
      op: Color(0xFF24292F),
    );
  }

  static TextSpan span(String code, TextStyle base, {String lang = 'cpp'}) {
    final p = _palette();
    final b = base.copyWith(color: p.text);
    final isPy = lang == 'python';
    final children = <TextSpan>[];
    var last = 0;

    TextStyle st(Color c, {bool strong = false, bool italic = false}) => b.copyWith(
          color: c,
          fontWeight: strong && p.bold ? FontWeight.bold : null,
          fontStyle: italic ? FontStyle.italic : null,
        );

    for (final m in (isPy ? _py : _cpp).allMatches(code)) {
      if (m.start > last) children.add(TextSpan(text: code.substring(last, m.start), style: b));
      TextStyle style = b;
      if (isPy) {
        if (m.group(1) != null) {
          style = st(p.comment, italic: true);
        } else if (m.group(2) != null) {
          style = st(p.string);
        } else if (m.group(3) != null) {
          style = st(p.type, strong: true);
        } else if (m.group(5) != null) {
          style = st(p.keyword, strong: true);
        } else if (m.group(7) != null) {
          style = st(p.number);
        } else if (m.group(9) != null) {
          style = st(p.bracket);
        } else if (m.group(10) != null) {
          style = st(p.op);
        }
      } else {
        if (m.group(1) != null) {
          style = st(p.comment, italic: true);
        } else if (m.group(2) != null) {
          style = st(p.string);
        } else if (m.group(4) != null) {
          style = st(p.preproc, strong: true);
        } else if (m.group(5) != null) {
          style = st(p.type, strong: true);
        } else if (m.group(7) != null) {
          style = st(p.keyword, strong: true);
        } else if (m.group(9) != null) {
          style = st(p.number);
        } else if (m.group(10) != null) {
          style = st(p.bracket, strong: true);
        } else if (m.group(11) != null) {
          style = st(p.op);
        }
      }
      children.add(TextSpan(text: m.group(0), style: style));
      last = m.end;
    }
    if (last < code.length) children.add(TextSpan(text: code.substring(last), style: b));
    return TextSpan(style: b, children: children);
  }
}