// Builds web/cpp/stdc.pch.gz: <bits/stdc++.h> precompiled, so programs that
// include it compile in about a second in the browser instead of ten.
// Rebuild it whenever the Clang version or the flags in web/cpp_compile_worker.js change:
//   cd "$(mktemp -d)" && npm init -y && npm install @yowasp/clang@21.1.4-3
//   node ~/iMeditatii/tool/make_cpp_pch.mjs
import { runClang } from '@yowasp/clang';
import fs from 'node:fs';
import zlib from 'node:zlib';

const web = new URL('../web/cpp/', import.meta.url);
const header = fs.readFileSync(new URL('bits/stdc++.h', web), 'utf8');
const r = await runClang(
  ['clang++', '-std=c++17', '-fno-exceptions', '-O1', '-x', 'c++-header', 'inc/bits/stdc++.h', '-o', 'stdc.pch'],
  { inc: { bits: { 'stdc++.h': header } } },
);
fs.writeFileSync(new URL('stdc.pch.gz', web), zlib.gzipSync(r['stdc.pch'], { level: 9 }));
console.log('web/cpp/stdc.pch.gz written');
