// Builds the precompiled headers the browser compiler uses:
//   web/cpp/iostream.pch.gz  <iostream>, which almost every program includes:
//                            compiles take about half a second instead of three
//   web/cpp/stdc.pch.gz      <bits/stdc++.h>: about a second instead of ten
// Rebuild it whenever the Clang version or the flags in web/cpp_compile_worker.js change:
//   cd "$(mktemp -d)" && npm init -y && npm install @yowasp/clang@21.1.4-3
//   node ~/iMeditatii/tool/make_cpp_pch.mjs
import { runClang } from '@yowasp/clang';
import fs from 'node:fs';
import zlib from 'node:zlib';

const web = new URL('../web/cpp/', import.meta.url);
const read = (path) => fs.readFileSync(new URL(path, web), 'utf8');
// The paths here are the ones the compile worker gives the headers.
const builds = [
  ['iostream.pch', 'pre/iostream.h', { pre: { 'iostream.h': read('pre/iostream.h') } }],
  ['stdc.pch', 'inc/bits/stdc++.h', { inc: { bits: { 'stdc++.h': read('bits/stdc++.h') } } }],
];
for (const [out, header, files] of builds) {
  const r = await runClang(['clang++', '-std=c++17', '-fno-exceptions', '-O1', '-x', 'c++-header', header, '-o', out], files);
  fs.writeFileSync(new URL(`${out}.gz`, web), zlib.gzipSync(r[out], { level: 9 }));
  console.log(`web/cpp/${out}.gz written`);
}
