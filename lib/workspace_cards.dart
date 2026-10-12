import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'clean_kit.dart';
import 'ui_components.dart' show Pb, PbButton, PbVariant, PbSize, PbLink;
import 'workspace_models.dart';
import 'workspace_screen.dart' show wsAgo, wsDocColor, wsDocIcon;

// =============================================================================
// Dashboard cards for the Atelier.
//   TeacherWorkspaceCard    recent documents + quick create, on the teacher panel
//   ReceivedMaterialsCard   what teachers have sent, on the student panel
// =============================================================================
const Color _blue = Color(0xFF3B82F6);
const Color _green = Color(0xFF10B981);
const Color _amber = Color(0xFFF59E0B);

Widget _pill(String text, Color c, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
          Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c)),
        ],
      ),
    );

Widget _docTile(String type, String lang, {double size = 38}) {
  final c = wsDocColor(type, lang);
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: c.withOpacity(0.13), borderRadius: BorderRadius.circular(size * 0.28)),
    child: Icon(wsDocIcon(type), size: size * 0.5, color: c),
  );
}

String _codeSummary(String code, String langLabel) {
  final lines = code.trim().isEmpty ? 0 : '\n'.allMatches(code.trim()).length + 1;
  return '$langLabel, $lines ${lines == 1 ? 'linie' : 'linii'}';
}

// ----------------------------------------------------------------- teacher
class TeacherWorkspaceCard extends StatefulWidget {
  final String uid;
  const TeacherWorkspaceCard({super.key, required this.uid});

  @override
  State<TeacherWorkspaceCard> createState() => _TeacherWorkspaceCardState();
}

class _TeacherWorkspaceCardState extends State<TeacherWorkspaceCard> {
  late final Stream<List<WsDoc>> _docs = Workspace.myDocs(widget.uid);
  late final Stream<List<WsShare>> _sent = Workspace.sentBy(widget.uid);

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ckDeco(r: 16),
      child: StreamBuilder<List<WsShare>>(
        stream: _sent,
        builder: (context, sentSnap) {
          final sent = sentSnap.data ?? const <WsShare>[];
          final byDoc = <String, List<WsShare>>{};
          for (final s in sent) {
            (byDoc[s.docId] ??= []).add(s);
          }
          return StreamBuilder<List<WsDoc>>(
            stream: _docs,
            builder: (context, snap) {
              final docs = snap.data ?? const <WsDoc>[];
              final loading = !snap.hasData && !snap.hasError;
              final unseen = sent.where((s) => !s.seen).length;
              final worked = sent.where((s) => s.studentEdited).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ckCardTitle(
                          Icons.auto_stories_outlined,
                          'Atelier',
                          trailing: PbLink(text: 'Deschide atelierul', fontSize: 13.5, onTap: () => context.go('/atelier')),
                        ),
                        Text(
                          'Caietul tău de notițe și un editor de cod care rulează pe loc. Ce scrii aici poți trimite direct elevilor.',
                          style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            PbButton(text: 'Pagină nouă', icon: Icons.sticky_note_2_outlined, size: PbSize.sm, onPressed: () => context.go('/atelier?nou=note')),
                            PbButton(
                              text: 'Fișier C++',
                              icon: Icons.code,
                              size: PbSize.sm,
                              variant: PbVariant.outlinePrimary,
                              onPressed: () => context.go('/atelier?nou=cpp'),
                            ),
                            PbButton(
                              text: 'Fișier Python',
                              icon: Icons.code,
                              size: PbSize.sm,
                              variant: PbVariant.outlineSecondary,
                              onPressed: () => context.go('/atelier?nou=python'),
                            ),
                            if (sent.isNotEmpty) ...[
                              _pill('${sent.length} trimise', _blue, icon: Icons.send),
                              if (unseen > 0) _pill('$unseen nedeschise', _amber, icon: Icons.schedule),
                              if (worked > 0) _pill('$worked lucrate de elevi', _green, icon: Icons.edit_outlined),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (loading)
                    const Padding(padding: EdgeInsets.all(18), child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Pb.primary))))
                  else
                    for (final d in docs.take(4))
                      CkHover(
                        onTap: () => context.go('/atelier?doc=${d.id}'),
                        builder: (h) {
                          final c = wsDocColor(d.type, d.lang);
                          final shares = byDoc[d.id] ?? const <WsShare>[];
                          final notSeen = shares.where((s) => !s.seen).length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              color: h ? c.withOpacity(0.05) : Colors.transparent,
                              border: Border(top: BorderSide(color: Pb.border), left: BorderSide(color: h ? c : Colors.transparent, width: 3)),
                            ),
                            padding: const EdgeInsets.fromLTRB(15, 10, 16, 10),
                            child: Row(
                              children: [
                                _docTile(d.type, d.lang),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(d.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: h ? c : Pb.text)),
                                      const SizedBox(height: 2),
                                      Text(
                                        [
                                          if (d.section.trim().isNotEmpty) d.section.trim(),
                                          d.isCode ? _codeSummary(d.content, d.langLabel) : 'Notițe',
                                          'modificat ${wsAgo(d.updatedAt)}',
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12.5, color: Pb.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                if (shares.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  _pill(
                                    notSeen == 0 ? 'văzut de ${shares.length}' : 'trimis la ${shares.length}',
                                    notSeen == 0 ? _green : _blue,
                                    icon: notSeen == 0 ? Icons.done_all : Icons.send,
                                  ),
                                ],
                                const SizedBox(width: 6),
                                Icon(Icons.chevron_right, size: 18, color: h ? c : Pb.border),
                              ],
                            ),
                          );
                        },
                      ),
                  if (!loading && docs.length > 4)
                    Container(
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: PbLink(text: 'Vezi toate cele ${docs.length} documente', fontSize: 13.5, onTap: () => context.go('/atelier')),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- student
class ReceivedMaterialsCard extends StatefulWidget {
  final String uid;
  const ReceivedMaterialsCard({super.key, required this.uid});

  @override
  State<ReceivedMaterialsCard> createState() => _ReceivedMaterialsCardState();
}

class _ReceivedMaterialsCardState extends State<ReceivedMaterialsCard> {
  late final Stream<List<WsShare>> _stream = Workspace.receivedBy(widget.uid);
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<WsShare>>(
      stream: _stream,
      builder: (context, snap) {
        final list = snap.data ?? const <WsShare>[];
        final fresh = list.where((s) => !s.seen).length;
        final shown = _all ? list : list.take(4).toList();

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: ckDeco(r: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, list.isEmpty ? 16 : 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ckCardTitle(
                      Icons.inventory_2_outlined,
                      'Materiale primite',
                      trailing: fresh > 0
                          ? _pill(fresh == 1 ? '1 nou' : '$fresh noi', _blue)
                          : (list.isEmpty ? null : Text('${list.length}', style: TextStyle(fontSize: 13, color: Pb.muted))),
                    ),
                    if (list.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Pb.hoverBg, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(snap.hasError ? Icons.cloud_off_outlined : Icons.mark_email_unread_outlined, size: 20, color: Pb.muted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                snap.hasError
                                    ? 'Nu am putut încărca materialele. Reîncarcă pagina.'
                                    : (snap.hasData
                                        ? 'Când un profesor îți trimite notițe sau un fișier de cod, apar aici.'
                                        : 'Se încarcă materialele...'),
                                style: TextStyle(fontSize: 13.5, color: Pb.muted, height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              for (final s in shown) _row(context, s),
              if (list.length > 4)
                Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: Pb.border))),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: PbLink(
                    text: _all ? 'Arată mai puține' : 'Vezi toate cele ${list.length} materiale',
                    fontSize: 13.5,
                    onTap: () => setState(() => _all = !_all),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, WsShare s) {
    final c = wsDocColor(s.type, s.lang);
    final preview = s.isCode ? _codeSummary(s.content, s.langLabel) : NoteContent.preview(s.content, max: 90);
    return CkHover(
      onTap: () => context.push('/material/${s.id}'),
      builder: (h) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: h ? c.withOpacity(0.05) : (s.seen ? Colors.transparent : _blue.withOpacity(0.04)),
          border: Border(top: BorderSide(color: Pb.border), left: BorderSide(color: h ? c : (s.seen ? Colors.transparent : _blue), width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(15, 11, 16, 11),
        child: Row(
          children: [
            _docTile(s.type, s.lang, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: s.seen ? FontWeight.w600 : FontWeight.w700, color: h ? c : Pb.text),
                        ),
                      ),
                      if (!s.seen) ...[const SizedBox(width: 8), _pill(s.version > 1 ? 'Actualizat' : 'Nou', _blue)],
                      if (s.seen && s.studentEdited) ...[const SizedBox(width: 8), _pill('Lucrat', _green, icon: Icons.edit_outlined)],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'De la ${s.teacherName}${preview.isEmpty ? '' : ' · $preview'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Pb.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(wsAgo(s.sentAt), style: TextStyle(fontSize: 12.5, color: Pb.muted)),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right, size: 18, color: h ? c : Pb.border),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
