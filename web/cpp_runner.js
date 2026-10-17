// window.imCpp: compiles and runs C++ in the student's browser, free and
// without limits. Clang is about 23 MB the first time (cached after); until
// it's in, run() answers {notReady} and the app runs the code on the server.
//   imCpp.warm()                       start loading Clang now
//   imCpp.isReady()                    loaded and waiting
//   imCpp.run(code, stdin, timeoutMs)  -> Promise<{stdout, stderr, status, seconds} | {notReady} | {failed, error}>
(function () {
  let compiler = null;
  let isReady = false;
  let seq = 0;
  const pending = new Map(); // id -> resolve
  let last = { code: null, result: null }; // the same code checked on many tests compiles once

  function start() {
    compiler = new Worker(new URL('cpp_compile_worker.js', document.baseURI), { type: 'module' });
    compiler.onmessage = (e) => {
      const m = e.data;
      if (m.ready) { isReady = true; return; }
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
    }).then((r) => {
      if (!r.failed) last = { code, result: r };
      return r;
    });
  }

  function execute(wasm, stdin, timeoutMs) {
    return new Promise((resolve) => {
      const w = new Worker(new URL('cpp_run_worker.js', document.baseURI), { type: 'module' });
      const done = (r) => { clearTimeout(timer); w.terminate(); resolve(r); };
      const timer = setTimeout(() => done({ stdout: '', stderr: '', status: 'Time Limit Exceeded', seconds: timeoutMs / 1000 }), timeoutMs);
      w.onmessage = (e) => {
        const r = e.data;
        done({ stdout: r.stdout, stderr: r.stderr, status: r.exit === 0 ? 'Accepted' : 'Runtime Error (NZEC)', seconds: r.seconds });
      };
      w.onerror = (e) => done({ failed: true, error: e.message || 'Programul nu a putut porni.' });
      w.postMessage({ wasm, stdin });
    });
  }

  window.imCpp = {
    warm() { if (!compiler) start(); },
    isReady() { return isReady; },
    async run(code, stdin, timeoutMs) {
      if (!isReady) { this.warm(); return { notReady: true }; }
      const c = await compile(code);
      if (c.failed) return { failed: true };
      if (c.error != null) return { stdout: '', stderr: c.error, status: 'Compilation Error' };
      return execute(c.wasm, stdin, timeoutMs);
    },
  };
})();
