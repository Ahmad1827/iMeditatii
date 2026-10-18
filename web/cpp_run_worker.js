// Runs compiled C++ programs (WebAssembly + WASI) with the given input, one
// at a time. It stays up between runs; the page stops it if a run takes too
// long and starts a new one.
//   in:  {module, stdin, file}   module: a compiled WebAssembly.Module
//        file: a problem with files: stdin goes in <file>.in in the program's
//        folder (in memory) and the keyboard is empty
//   out: {stdout, stderr, exit, seconds}, and with file: {file} (what it wrote
//        in <file>.out, null if it didn't create it)
import { WASI, File, OpenFile, ConsoleStdout, PreopenDirectory, WASIProcExit } from 'https://cdn.jsdelivr.net/npm/@bjorn3/browser_wasi_shim@0.4.2/dist/index.js';

const LIMIT = 4 << 20; // keep at most 4 MB of output

onmessage = async (e) => {
  const { module, stdin, file } = e.data;
  const sink = () => {
    const parts = [];
    let size = 0;
    return {
      parts,
      write: (b) => { if (size < LIMIT) { parts.push(b.slice()); size += b.length; } },
    };
  };
  const out = sink(), err = sink();
  const enc = new TextEncoder();
  const dir = file ? new PreopenDirectory('.', new Map([[`${file}.in`, new File(enc.encode(stdin))]])) : null;
  const wasi = new WASI(
    ['main'],
    [],
    [
      new OpenFile(new File(file ? new Uint8Array() : enc.encode(stdin))),
      new ConsoleStdout(out.write),
      new ConsoleStdout(err.write),
      ...(dir ? [dir] : []),
    ],
    { debug: false },
  );
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
  const written = dir?.dir.contents.get(`${file}.out`);
  postMessage({
    stdout: text(out),
    stderr: text(err).trim(),
    exit,
    seconds: (performance.now() - t) / 1000,
    ...(file ? { file: written instanceof File ? new TextDecoder().decode(written.data) : null } : {}),
  });
};
