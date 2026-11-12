// =============================================================================
// WHICH TOOL SOLVES A PROBLEM: its kind picks the workspace
// =============================================================================

import 'package:flutter/material.dart';

import '../acs_data.dart';
import '../acs_kit.dart';
import 'ws_common.dart';
import 'ws_apd.dart';
import 'ws_asm.dart';
import 'ws_c.dart';
import 'ws_circuit.dart';
import 'ws_crypto.dart';
import 'ws_ds.dart';
import 'ws_egc.dart';
import 'ws_fields.dart';
import 'ws_grila.dart';
import 'ws_lfa.dart';
import 'ws_logic.dart';
import 'ws_math.dart';
import 'ws_octave.dart';
import 'ws_rowops.dart';
import 'ws_shell.dart';
import 'ws_sim.dart';

Widget buildWorkspace(AcsProblem p, AcsInk ink, bool narrow, Verdict onVerdict) {
  switch (p.kind) {
    case 'shell':
      return ShellWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'asm':
      return AsmWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'c':
      return CWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'ds':
      return DsWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'logic':
      return LogicWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'octave':
      return OctaveWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'math':
      return MathWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'circuit':
      return CircuitWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'sim':
      return SimWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'grila':
      return GrilaWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'threads':
      return ApdWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'transform':
      return TransformWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'raster':
      return RasterWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'net':
      return NetWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'market':
      return MarketWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'crypto':
      return CryptoWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'lfa':
      return LfaWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
    case 'rowops':
      return RowOpsWorkspace(problem: p, ink: ink, onVerdict: onVerdict, narrow: narrow);
  }
  return AcsBox(ink, title: p.kind, child: Text('Unealta pentru „${p.kind}” nu există.', style: ink.mono(14, color: ink.muted)));
}
