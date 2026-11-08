"""Runs a USO task's reference solution in the real bash, to get what the checks expect.

The task's home (~) is a temporary folder; LC_ALL=C, like the app's shell.
"""
import os, shutil, subprocess, tempfile

ENV = {'LC_ALL': 'C', 'PATH': '/usr/bin:/bin', 'USER': 'student', 'LOGNAME': 'student'}


def _real(home, path):
    if path == '~':
        return home
    assert path.startswith('~/'), f'setup paths start with ~/: {path}'
    return os.path.join(home, path[2:])


def materialize(home, setup):
    for e in setup:
        p = _real(home, e['path'].rstrip('/'))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        if e.get('dir') or e['path'].endswith('/'):
            os.makedirs(p, exist_ok=True)
        elif 'link' in e:
            os.symlink(e['link'], p)
        else:
            with open(p, 'w') as f:
                f.write(e.get('content', ''))
        if 'mode' in e and 'link' not in e:
            os.chmod(p, int(str(e['mode']), 8))


def run(home, script, cwd='~', stdin=''):
    env = dict(ENV, HOME=home)
    r = subprocess.run(['/bin/bash', '--norc', '--noprofile', '-c', script], cwd=_real(home, cwd), env=env,
                       input=stdin, capture_output=True, text=True, timeout=20)
    return r.stdout, r.stderr, r.returncode


class Sandbox:
    """A home folder with the task's files; the reference solution run in it."""

    def __init__(self, setup, reference=(), cwd='~'):
        self.root = tempfile.mkdtemp(prefix='acs_uso_')
        self.home = os.path.join(self.root, 'home')
        os.makedirs(self.home)
        materialize(self.home, setup)
        if reference:
            script = '\n'.join(reference)
            out, err, st = run(self.home, script, cwd)
            if err.strip():
                raise SystemExit(f'reference failed: {script!r}\n{err}')

    def read(self, path):
        with open(_real(self.home, path)) as f:
            return f.read()

    def copy(self):
        other = Sandbox.__new__(Sandbox)
        other.root = tempfile.mkdtemp(prefix='acs_uso_')
        other.home = os.path.join(other.root, 'home')
        shutil.copytree(self.home, other.home, symlinks=True)
        return other

    def close(self):
        shutil.rmtree(self.root, ignore_errors=True)


def fill_expectations(spec):
    """Checks marked with "from_ref" get their expected text from the reference run."""
    box = Sandbox(spec.get('setup', []), spec.get('reference', []), spec.get('cwd', '~'))
    try:
        for c in spec['checks']:
            if c.pop('from_ref', False):
                c['equals'] = box.read(c['path'])
            if c['type'] == 'script':
                for r in c['runs']:
                    if r.pop('from_ref', False):
                        b2 = box.copy()
                        try:
                            materialize(b2.home, r.get('setup', []))
                            args = ' '.join("'" + a.replace("'", "'\\''") + "'" for a in r.get('args', []))
                            out, err, st = run(b2.home, f"bash {c['path']} {args}", r.get('cwd', '~'), r.get('stdin', ''))
                            if 'after' in r:
                                out, _, _ = run(b2.home, r['after'], r.get('cwd', '~'))
                            r['stdout'] = out
                            r.setdefault('status', st)
                        finally:
                            b2.close()
    finally:
        box.close()
    return spec
