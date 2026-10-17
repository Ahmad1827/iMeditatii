// Compiles C++ in the browser with Clang 21 built for WebAssembly
// (@yowasp/clang). Stays loaded between runs; programs run elsewhere
// (cpp_run_worker.js), so stopping an endless loop doesn't cost the compiler.
//   in:  {id, code}
//   out: {ready} once Clang is loaded, or {loadError}
//        {id, wasm} or {id, error} (the compiler's messages)
// The flags must match the ones tool/make_cpp_pch.mjs builds the .pch files with.
import { runClang, runLLVM } from 'https://cdn.jsdelivr.net/npm/@yowasp/clang@21.1.4-3/gen/bundle.js';

const FLAGS = ['-std=c++17', '-fno-exceptions', '-O1'];
const STACK = '-Wl,-z,stack-size=8388608'; // 8 MB, like a judge: big local arrays are common
const text = (path) => fetch(path).then((r) => r.text());
const header = text('cpp/bits/stdc++.h');
const iostreamHeader = text('cpp/pre/iostream.h');

// Parsing the standard headers is nearly all of a compile, so they come
// precompiled: <iostream> (fetched as soon as Clang is in, nearly every
// program needs it) and <bits/stdc++.h> (the first time a program has it).
const pch = {};
function precompiled(name) {
  pch[name] ??= (async () => {
    const r = await fetch(`cpp/${name}.pch.gz`);
    if (!r.ok) throw new Error(`pch ${r.status}`);
    let bytes = new Uint8Array(await r.arrayBuffer());
    if (bytes[0] === 0x1f && bytes[1] === 0x8b) {
      // still gzipped (the server didn't unpack it on the way)
      bytes = new Uint8Array(await new Response(new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer());
    }
    return bytes;
  })();
  pch[name].catch(() => { delete pch[name]; });
  return pch[name];
}

const includes = (code, h) => new RegExp(`#\\s*include\\s*<${h}>`).test(code);

async function compile(code, usePch = true) {
  let log = '';
  const dec = new TextDecoder();
  const out = (b) => { if (b) log += dec.decode(b, { stream: true }); };
  const files = { 'main.cpp': code, inc: { bits: { 'stdc++.h': await header } }, pre: { 'iostream.h': await iostreamHeader } };
  const args = ['clang++', ...FLAGS, '-I', 'inc'];
  // Only a header the program includes itself, so what compiles here is what compiles with g++.
  const name = includes(code, 'bits/stdc\\+\\+\\.h') ? 'stdc' : includes(code, 'iostream') ? 'iostream' : null;
  if (name && usePch) {
    try {
      files[`${name}.pch`] = await precompiled(name);
      args.push('-include-pch', `${name}.pch`);
    } catch (_) {
      // compile it from the header instead: slower, same result
    }
  }
  try {
    const r = await runClang([...args, STACK, 'main.cpp', '-o', 'a.out'], files, { stdout: out, stderr: out, decodeASCII: false });
    return { wasm: r['a.out'] };
  } catch (e) {
    // a precompiled header that doesn't fit this Clang: without it, rather than fail every program
    if (args.includes('-include-pch') && /precompiled|PCH|\.pch/.test(log)) return compile(code, false);
    return { error: log.trim() || String(e && e.message ? e.message : e) };
  }
}

// Load Clang now: fetch it quietly (runClang would log every percent of the
// download to the console), then compile the smallest program.
const quiet = { stdout: () => {}, stderr: () => {}, fetchProgress: () => {} };
Promise.resolve(runLLVM(['size', '--version'], {}, quiet)).catch(() => {}).then(() => compile('int main() {}')).then(
  (r) => {
    postMessage(r.wasm ? { ready: true } : { loadError: r.error });
    if (r.wasm) precompiled('iostream').catch(() => {});
  },
  (e) => postMessage({ loadError: String(e) }),
);

onmessage = async (e) => {
  const { id, code } = e.data;
  const r = await compile(code);
  postMessage({ id, ...r }, r.wasm ? [r.wasm.buffer] : []);
};
