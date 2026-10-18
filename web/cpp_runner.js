// window.imCpp: compiles and runs C++ in the student's browser, free and
// without limits. Clang is about 23 MB the first time (cached after); until
// it's in, run() answers {notReady} and the app runs the code on the server.
//   imCpp.warm()                       start loading Clang now
//   imCpp.isReady()                    loaded and waiting
//   imCpp.run(code, stdin, timeoutMs, file)  -> Promise<{stdout, stderr, status, seconds} | {notReady} | {failed, error}>
//     file: a problem with files: stdin goes in <file>.in, the keyboard is
//     empty, and stdout is <file>.out (plus console: the screen, noFile)
(function () {
  let compiler = null;
  let runner = null; // runs programs; kept between runs, replaced after one is stopped
  let isReady = false;
  let seq = 0;
  const pending = new Map(); // id -> resolve
  let last = { code: null, result: null }; // the same code checked on many tests compiles once (to a WebAssembly.Module)

  function start() {
    compiler = new Worker(new URL('cpp_compile_worker.js', document.baseURI), { type: 'module' });
    compiler.onmessage = (e) => {
      const m = e.data;
      if (m.ready) { isReady = true; runner ??= newRunner(); return; }
      if (m.loadError) { stop(); return; }
      const p = pending.get(m.id);
      if (p) { pending.delete(m.id); p(m); }
    };
    compiler.onerror = () => {
      for (const p of pending.values()) p({ failed: true });
      pending.clear();
      stop();
    };
  }

  function stop() {
    if (compiler) compiler.terminate();
    compiler = null;
    isReady = false;
  }

  function compile(code) {
    if (code === last.code) return Promise.resolve(last.result);
    const id = ++seq;
    return new Promise((resolve) => {
      pending.set(id, resolve);
      compiler.postMessage({ id, code });
    }).then(async (r) => {
      if (r.wasm) r = { module: await WebAssembly.compile(r.wasm) };
      if (!r.failed) last = { code, result: r };
      return r;
    });
  }

  function newRunner() {
    return new Worker(new URL('cpp_run_worker.js', document.baseURI), { type: 'module' });
  }

  function execute(module, stdin, timeoutMs, file) {
    return new Promise((resolve) => {
      const w = (runner ??= newRunner());
      const replace = () => { w.terminate(); if (runner === w) runner = null; };
      const done = (r) => { clearTimeout(timer); w.onmessage = w.onerror = null; resolve(r); };
      const timer = setTimeout(() => {
        replace(); // stuck in a loop: only stopping the worker stops it
        done({ stdout: '', stderr: '', status: 'Time Limit Exceeded', seconds: timeoutMs / 1000 });
      }, timeoutMs);
      w.onmessage = (e) => {
        const r = e.data;
        const status = r.exit === 0 ? 'Accepted' : 'Runtime Error (NZEC)';
        done(file
          ? { stdout: r.file ?? '', console: r.stdout, noFile: r.file == null, stderr: r.stderr, status, seconds: r.seconds }
          : { stdout: r.stdout, stderr: r.stderr, status, seconds: r.seconds });
      };
      w.onerror = (e) => { replace(); done({ failed: true, error: e.message || 'Programul nu a putut porni.' }); };
      w.postMessage({ module, stdin, file });
    });
  }

  window.imCpp = {
    warm() { if (!compiler) start(); },
    isReady() { return isReady; },
    async run(code, stdin, timeoutMs, file) {
      if (!isReady) { this.warm(); return { notReady: true }; }
      const c = await compile(code);
      if (c.failed) return { failed: true };
      if (c.error != null) return { stdout: '', stderr: c.error, status: 'Compilation Error' };
      return execute(c.module, stdin, timeoutMs, file || null);
    },
  };
})();
