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

/// Neutral aliases for new code. Old names keep working everywhere.
typedef AppCard = RetroBlock;
typedef AppButton = RetroButton;

// =============================================================================
// CARD
// =============================================================================
class RetroBlock extends StatelessWidget {
  final Widget child;
  final Color? bgColor;
  final double padding;
  final double shadowOffset;
  final Color? borderColor;

  /// Clean turns mustard/beige fills into plain surfaces; true opts out.
  final bool preserveColor;

  /// Clean elevation level: 0 flat, 1 card, 2 raised.
  final int elevation;

  const RetroBlock({
    super.key,
    required this.child,
    this.bgColor,
    this.padding = 24.0,
    this.shadowOffset = 6.0,
    this.borderColor,
    this.preserveColor = false,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final requested = bgColor ?? AppColors.cardBg;
        return Container(
          decoration: s.card(
            bg: preserveColor ? requested : s.surfaceFor(requested),
            retroShadow: shadowOffset,
            retroBorder: borderColor,
            cleanLevel: elevation,
          ),
          padding: EdgeInsets.all(padding),
          child: child,
        );
      },
    );
  }
}

// =============================================================================
// BUTTON
// =============================================================================
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
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return StyleBuilder(
      builder: (context, s) {
        final bg = widget.isLoading ? Colors.grey : s.buttonFill(widget.bgColor ?? AppColors.sunset);
        var fg = widget.textColor ?? Colors.white;
        if (s.isClean && s.isSurface(bg)) fg = AppColors.ink;

        return MouseRegion(
          cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
            onTapUp: widget.isLoading
                ? null
                : (_) {
                    setState(() => _pressed = false);
                    widget.onPressed();
                  },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 110),
              curve: Curves.easeOut,
              width: widget.isFullWidth ? double.infinity : null,
              transform: s.buttonTransform(pressed: _pressed, hovered: _hovered),
              transformAlignment: Alignment.center,
              decoration: s.button(bg: bg, pressed: _pressed, hovered: _hovered),
              padding: widget.padding,
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: fg, strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: fg, size: widget.fontSize + (s.isClean ? 1 : 2)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          s.caps(widget.text),
                          textAlign: TextAlign.center,
                          style: s.buttonText(fg, widget.fontSize),
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
// BADGE — solid block (Retro) / soft tinted chip (Clean)
// =============================================================================
class AppBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor; // Retro only; Clean derives it from [color]
  final IconData? icon;
  final bool outlined; // Retro only
  final double fontSize;

  const AppBadge({
    super.key,
    required this.text,
    required this.color,
    this.textColor = Colors.white,
    this.icon,
    this.outlined = false,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);
    final fg = s.isClean ? s.accentText(color) : textColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s.isClean ? 9 : 8, vertical: s.isClean ? 4 : 3),
      decoration: BoxDecoration(
        color: s.isClean ? s.tint(color) : color,
        borderRadius: s.rChip,
        border: (s.isRetro && outlined) ? Border.all(color: AppColors.border, width: 2) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            s.caps(text),
            style: TextStyle(
              color: fg,
              fontSize: s.isClean ? fontSize + 1 : fontSize,
              fontWeight: s.isClean ? FontWeight.w600 : FontWeight.w900,
              letterSpacing: s.isClean ? 0 : 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB — folder tab (Retro) / underline tab (Clean)
// =============================================================================
class AppTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isMobile;

  const AppTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);

    final Widget tab = s.isClean
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 14, vertical: isMobile ? 9 : 11),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: selected ? AppColors.ink : Colors.transparent, width: 2),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppColors.ink : AppColors.textMuted,
              ),
            ),
          )
        : Container(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.mustard : AppColors.cloud,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 2.5),
                left: BorderSide(color: AppColors.border, width: 2.5),
                right: BorderSide(color: AppColors.border, width: 2.5),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w900,
                color: selected && AppColors.isDark ? const Color(0xFF10161A) : AppColors.ink,
                letterSpacing: 1.0,
                decoration: selected ? TextDecoration.none : TextDecoration.underline,
              ),
            ),
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: tab),
    );
  }
}

// =============================================================================
// DIVIDER / ICON TILE
// =============================================================================
class AppDivider extends StatelessWidget {
  final double retroThickness;
  const AppDivider({super.key, this.retroThickness = 2});

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);
    return Container(height: s.isClean ? 1 : retroThickness, color: s.line);
  }
}

class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double iconSize;
  final double padding;

  const AppIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.iconSize = 28,
    this.padding = 14,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);
    if (s.isClean) {
      return Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(color: s.tint(color), borderRadius: s.rTile),
        child: Icon(icon, size: iconSize, color: s.accentText(color)),
      );
    }
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.border, width: 2.5),
        boxShadow: s.hardShadow(3),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}

// =============================================================================
// CALLOUT — tips, warnings, results
// Clean splits an all-caps first line ending in ":" into a proper title.
// =============================================================================
class AppCallout extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final double fontSize;

  const AppCallout({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);

    if (s.isRetro) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          border: Border(left: BorderSide(color: color, width: 4.5)),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: AppColors.ink, height: 1.55),
        ),
      );
    }

    String? title;
    var content = text;
    final nl = text.indexOf('\n');
    if (nl > 0) {
      final first = text.substring(0, nl).trim();
      if (first.endsWith(':')) {
        title = AppStyle.sentence(first.substring(0, first.length - 1));
        content = text.substring(nl + 1).trim();
      }
    }

    return ClipRRect(
      borderRadius: s.rInset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: color.withOpacity(s.isDark ? 0.12 : 0.07),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 18, color: s.accentText(color)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: s.accentText(color)),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(content, style: s.body(fontSize, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROBLEM SPEC — Input / Output / Constraints / Examples
// Clean: pbinfo-style statement table. Retro: stacked spec blocks.
// Reads: input, output, restrictii|constraints|restrictions, examples (Map|List).
// =============================================================================
class ProblemSpec extends StatelessWidget {
  final String? input;
  final String? output;
  final String? constraints;
  final List<Map<String, String>> examples;
  final bool isMobile;

  const ProblemSpec({
    super.key,
    this.input,
    this.output,
    this.constraints,
    this.examples = const [],
    this.isMobile = false,
  });

  factory ProblemSpec.fromData(Map<String, dynamic> data, {bool isMobile = false}) {
    String? read(List<String> keys) {
      for (final k in keys) {
        final v = data[k];
        if (v == null) continue;
        final str = v is List ? v.map((e) => '• $e').join('\n') : v.toString();
        final t = str.trim();
        if (t.isNotEmpty && t != '-') return t;
      }
      return null;
    }

    final ex = <Map<String, String>>[];
    void add(dynamic e) {
      if (e is Map) {
        ex.add({
          'input': (e['input'] ?? '').toString(),
          'output': (e['output'] ?? '').toString(),
        });
      }
    }

    final raw = data['examples'] ?? data['exemple'];
    if (raw is Map) {
      add(raw);
    } else if (raw is List) {
      raw.forEach(add);
    }

    return ProblemSpec(
      input: read(['input', 'date_intrare']),
      output: read(['output', 'date_iesire']),
      constraints: read(['restrictii', 'constraints', 'restrictions']),
      examples: ex,
      isMobile: isMobile,
    );
  }

  bool get isEmpty => input == null && output == null && constraints == null && examples.isEmpty;

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);
    if (isEmpty) return const SizedBox.shrink();
    return s.isClean ? _buildClean(s) : _buildRetro(s);
  }

  // ---------------------------------------------------------------- RETRO
  Widget _buildRetro(AppStyle s) {
    final blocks = <Widget>[];
    void add(String title, String content, {bool mono = false}) {
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: 12));
      blocks.add(_RetroSpecBlock(title: title, content: content, isMobile: isMobile, mono: mono));
    }

    if (input != null) add('INPUT FORMAT', input!);
    if (output != null) add('OUTPUT FORMAT', output!);
    if (constraints != null) add('CONSTRAINTS', constraints!);
    for (var i = 0; i < examples.length; i++) {
      final n = examples.length > 1 ? ' #${i + 1}' : '';
      add('EXAMPLE INPUT$n', examples[i]['input']!, mono: true);
      add('EXAMPLE OUTPUT$n', examples[i]['output']!, mono: true);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  // ---------------------------------------------------------------- CLEAN
  Widget _buildClean(AppStyle s) {
    final rows = <MapEntry<String, String>>[
      if (input != null) MapEntry('Date de intrare', input!),
      if (output != null) MapEntry('Date de ieșire', output!),
      if (constraints != null) MapEntry('Restricții și precizări', constraints!),
    ];

    final labelStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink);
    final valueStyle = s.body(isMobile ? 14.5 : 15, height: 1.6);

    Widget specTable;
    if (rows.isEmpty) {
      specTable = const SizedBox.shrink();
    } else if (isMobile) {
      specTable = Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: s.rInset, border: Border.all(color: s.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Container(height: 1, color: s.line),
              Container(
                color: s.inset,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Text(rows[i].key, style: labelStyle),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: SelectableText(rows[i].value, style: valueStyle),
              ),
            ],
          ],
        ),
      );
    } else {
      specTable = ClipRRect(
        borderRadius: s.rInset,
        child: Table(
          border: TableBorder.all(color: s.line, borderRadius: s.rInset),
          columnWidths: const {0: FixedColumnWidth(180), 1: FlexColumnWidth()},
          children: [
            for (final r in rows)
              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.fill,
                    child: Container(
                      color: s.inset,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Text(r.key, style: labelStyle),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: SelectableText(r.value, style: valueStyle),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        specTable,
        for (var i = 0; i < examples.length; i++) ...[
          SizedBox(height: rows.isEmpty && i == 0 ? 0 : 20),
          Text(examples.length > 1 ? 'Exemplul ${i + 1}' : 'Exemplu', style: s.heading(15)),
          const SizedBox(height: 8),
          _CleanExampleTable(
            input: examples[i]['input']!,
            output: examples[i]['output']!,
            isMobile: isMobile,
          ),
        ],
      ],
    );
  }
}

class _RetroSpecBlock extends StatelessWidget {
  final String title;
  final String content;
  final bool isMobile;
  final bool mono;

  const _RetroSpecBlock({required this.title, required this.content, required this.isMobile, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);
    final size = isMobile ? 13.0 : 16.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w900, color: AppColors.sky, letterSpacing: 1.2),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: AppColors.cloud,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: SelectableText(
            content,
            style: mono
                ? s.mono(size, color: AppColors.ink, height: 1.4)
                : TextStyle(fontSize: size, color: AppColors.ink, fontWeight: FontWeight.w700, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _CleanExampleTable extends StatelessWidget {
  final String input;
  final String output;
  final bool isMobile;

  const _CleanExampleTable({required this.input, required this.output, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final s = AppStyle.of(context);

    Widget header(String t) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        );

    Widget code(String t) => Padding(
          padding: const EdgeInsets.all(14),
          child: SelectableText(t.isEmpty ? ' ' : t, style: s.mono(isMobile ? 13 : 14, color: AppColors.ink, height: 1.5)),
        );

    final headerDecoration = BoxDecoration(color: s.inset);

    return ClipRRect(
      borderRadius: s.rInset,
      child: Table(
        border: TableBorder.all(color: s.line, borderRadius: s.rInset),
        children: isMobile
            ? [
                TableRow(decoration: headerDecoration, children: [header('Intrare')]),
                TableRow(children: [code(input)]),
                TableRow(decoration: headerDecoration, children: [header('Ieșire')]),
                TableRow(children: [code(output)]),
              ]
            : [
                TableRow(decoration: headerDecoration, children: [header('Intrare'), header('Ieșire')]),
                TableRow(children: [code(input), code(output)]),
              ],
      ),
    );
  }
}