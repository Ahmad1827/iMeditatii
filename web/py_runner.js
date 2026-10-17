// window.imPython: runs Python in the student's browser, free and without
// limits. The first run loads Python (about 10 MB, cached after that); a
// program that runs longer than the time limit is stopped.
//   imPython.warm()                       start loading Python now
//   imPython.isReady()                    loaded and waiting
//   imPython.run(code, stdin, timeoutMs)  -> Promise<{stdout, stderr, status, seconds} | {failed, error}>
(function () {
  let worker = null;
  let loaded = null; // Promise: resolves when Python is in, rejects if it can't load
  let isReady = false;
  let seq = 0;
  const pending = new Map(); // id -> {started(), done(result)}

  function start() {
    isReady = false;
    worker = new Worker(new URL('py_worker.js', document.baseURI));
    let ok, fail;
    loaded = new Promise((res, rej) => { ok = res; fail = rej; });
    loaded.catch(() => {});
    const giveUp = setTimeout(() => fail(new Error('Python s-a încărcat prea greu.')), 90000);
    worker.onmessage = (e) => {
      const m = e.data;
      if (m.ready) { clearTimeout(giveUp); isReady = true; ok(); return; }
      if (m.loadError) { clearTimeout(giveUp); fail(new Error(m.loadError)); return; }
      const p = pending.get(m.id);
      if (!p) return;
      if (m.started) { p.started(); return; }
      pending.delete(m.id);
      p.done(m);
    };
    worker.onerror = (e) => {
      clearTimeout(giveUp);
      fail(new Error(e.message || 'Python nu a putut porni.'));
      for (const p of pending.values()) p.done({ failed: true, error: e.message || 'Python s-a oprit.' });
      pending.clear();
      stop();
    };
  }

  function stop() {
    if (worker) worker.terminate();
    worker = null;
    loaded = null;
    isReady = false;
  }

  window.imPython = {
    warm() { if (!worker) start(); },
    isReady() { return isReady; },
    async run(code, stdin, timeoutMs) {
      if (!worker) start();
      try {
        await loaded;
      } catch (e) {
        stop(); // try again from scratch next time
        return { failed: true, error: String(e.message || e) };
      }
      const id = ++seq;
      const w = worker;
      return new Promise((resolve) => {
        let timer = null;
        pending.set(id, {
          started() {
            timer = setTimeout(() => {
              pending.delete(id);
              if (worker === w) stop(); // the next run starts a fresh Python
              resolve({ stdout: '', stderr: '', status: 'Time Limit Exceeded', seconds: timeoutMs / 1000 });
            }, timeoutMs);
          },
          done(r) { clearTimeout(timer); resolve(r); },
        });
        w.postMessage({ id, code, stdin });
      });
    },
  };
})();
