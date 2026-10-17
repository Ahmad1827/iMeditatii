// Runs Python (Pyodide, the real CPython built for the browser) away from the
// page, so an endless loop can't freeze the site: the page just stops this
// worker and starts a new one. Messages:
//   in:  {id, code, stdin}
//   out: {ready} once Python is loaded, or {loadError}
//        {id, started} once the program's imports are in, the clock starts
//        {id, stdout, stderr, status, seconds} when it's done
importScripts('https://cdn.jsdelivr.net/pyodide/v0.29.0/full/pyodide.js');

const RUNNER = `
import sys, io, time, traceback, linecache

def __im_run(src, data):
    out, err = io.StringIO(), io.StringIO()
    sys.stdin, sys.stdout, sys.stderr = io.StringIO(data), out, err
    status = 'Accepted'
    linecache.cache['main.py'] = (len(src), None, src.splitlines(True), 'main.py')  # so errors show the line
    t = time.perf_counter()
    try:
        exec(compile(src, 'main.py', 'exec'), {'__name__': '__main__'})
    except SystemExit as e:
        if e.code not in (None, 0):
            status = 'Runtime Error (NZEC)'
    except SyntaxError as e:
        status = 'Compilation Error'
        err.write(''.join(traceback.format_exception_only(type(e), e)))
    except BaseException as e:
        status = 'Runtime Error (NZEC)'
        # only the student's own lines, not ours
        frames = [f for f in traceback.extract_tb(e.__traceback__) if f.filename == 'main.py']
        err.write('Traceback (most recent call last):\\n' + ''.join(traceback.format_list(frames)) + ''.join(traceback.format_exception_only(type(e), e)))
    finally:
        sys.stdin, sys.stdout, sys.stderr = sys.__stdin__, sys.__stdout__, sys.__stderr__
    return [out.getvalue(), err.getvalue(), status, time.perf_counter() - t]
`;

const ready = (async () => {
  const py = await loadPyodide();
  py.runPython(RUNNER);
  return py;
})();

ready.then(
  () => postMessage({ ready: true }),
  (e) => postMessage({ loadError: String(e && e.message ? e.message : e) }),
);

onmessage = async (e) => {
  const { id, code, stdin } = e.data;
  const py = await ready;
  try {
    await py.loadPackagesFromImports(code); // numpy and friends, on demand
  } catch (_) {
    // not a package Pyodide has: the import fails in the program itself, with a normal error
  }
  postMessage({ id, started: true });
  const r = py.globals.get('__im_run')(code, stdin);
  const [stdout, stderr, status, seconds] = r.toJs();
  r.destroy();
  postMessage({ id, stdout, stderr, status, seconds });
};
