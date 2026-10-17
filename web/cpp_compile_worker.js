// Compiles C++ in the browser with Clang 21 built for WebAssembly
// (@yowasp/clang). Stays loaded between runs; programs run elsewhere
// (cpp_run_worker.js), so stopping an endless loop doesn't cost the compiler.
//   in:  {id, code}
//   out: {ready} once Clang is loaded, or {loadError}
//        {id, wasm} or {id, error} (the compiler's messages)
// The flags must match the ones tool/make_cpp_pch.mjs builds cpp/stdc.pch.gz with.
import { runClang } from 'https://cdn.jsdelivr.net/npm/@yowasp/clang@21.1.4-3/gen/bundle.js';

const FLAGS = ['-std=c++17', '-fno-exceptions', '-O1'];
const STACK = '-Wl,-z,stack-size=8388608'; // 8 MB, like a judge: big local arrays are common
const header = fetch('cpp/bits/stdc++.h').then((r) => r.text());

// <bits/stdc++.h> precompiled, fetched the first time a program includes it.
let pch = null;
function precompiled() {
  pch ??= (async () => {
    const r = await fetch('cpp/stdc.pch.gz');
    if (!r.ok) throw new Error(`pch ${r.status}`);
    let bytes = new Uint8Array(await r.arrayBuffer());
    if (bytes[0] === 0x1f && bytes[1] === 0x8b) {
      // still gzipped (the server didn't unpack it on the way)
      bytes = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer());
    }
    return bytes;
  })();
  pch.catch(() => { pch = null; });
  return pch;
}

async function compile(code) {
  let log = '';
  const dec = new TextDecoder();
  const out = (b) => { if (b) log += dec.decode(b, { stream: true }); };
  const files = { 'main.cpp': code, inc: { bits: { 'stdc++.h': await header } } };
  const args = ['clang++', ...FLAGS, '-I', 'inc'];
  if (/#\s*include\s*<bits\/stdc\+\+\.h>/.test(code)) {
    try {
      files['stdc.pch'] = await precompiled();
      args.push('-include-pch', 'stdc.pch');
    } catch (_) {
      // compile it from the header instead: slower, same result
    }
  }
  try {
    const r = await runClang([...args, STACK, 'main.cpp', '-o', 'a.out'], files, { stdout: out, stderr: out, decodeASCII: false });
    return { wasm: r['a.out'] };
  } catch (e) {
    return { error: log.trim() || String(e && e.message ? e.message : e) };
  }
}

// Load Clang now, by compiling the smallest program.
compile('int main() {}').then(
  (r) => postMessage(r.wasm ? { ready: true } : { loadError: r.error }),
  (e) => postMessage({ loadError: String(e) }),
);

onmessage = async (e) => {
  const { id, code } = e.data;
  const r = await compile(code);
  postMessage({ id, ...r }, r.wasm ? [r.wasm.buffer] : []);
};
