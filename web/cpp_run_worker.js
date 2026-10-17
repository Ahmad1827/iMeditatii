// Runs compiled C++ programs (WebAssembly + WASI) with the given input, one
// at a time. It stays up between runs; the page stops it if a run takes too
// long and starts a new one.
//   in:  {module, stdin}   module: a compiled WebAssembly.Module
//   out: {stdout, stderr, exit, seconds}
import { WASI, File, OpenFile, ConsoleStdout, WASIProcExit } from 'https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.2/dist/index.js';

const LIMIT = 4 << 20; // keep at most 4 MB of output

onmessage = async (e) => {
  const { module, stdin } = e.data;
  const sink = () => {
    const parts = [];
    let size = 0;
    return {
      parts,
      write: (b) => { if (size < LIMIT) { parts.push(b.slice()); size += b.length; } },
    };
  };
  const out = sink(), err = sink();
  const wasi = new WASI(['main'], [], [
    new OpenFile(new File(new TextEncoder().encode(stdin))),
    new ConsoleStdout(out.write),
    new ConsoleStdout(err.write),
  ]);
  const t = performance.now();
  let exit = 0;
  try {
    const inst = await WebAssembly.instantiate(module, { wasi_snapshot_preview1: wasi.wasiImport });
    exit = wasi.start(inst);
  } catch (x) {
    if (x instanceof WASIProcExit) {
      exit = x.code;
    } else {
      exit = -1;
      err.write(new TextEncoder().encode(`\n${x && x.message ? x.message : x}`)); // a crash: out of bounds, abort...
    }
  }
  const text = (s) => new TextDecoder().decode(new Uint8Array(s.parts.flatMap((b) => [...b])));
  postMessage({ stdout: text(out), stderr: text(err).trim(), exit, seconds: (performance.now() - t) / 1000 });
};
