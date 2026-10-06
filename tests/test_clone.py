import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

class GitHubClone(unittest.TestCase):
    def test_shallow_default_branch_and_preserve_existing_work(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            upstream = root / 'upstream'
            def git(*args):
                return subprocess.check_output(['git', *args], text=True).strip()
            git('init', '-q', str(upstream))
            git('-C', str(upstream), 'config', 'commit.gpgsign', 'false')
            git('-C', str(upstream), 'config', 'user.name', 'Test')
            git('-C', str(upstream), 'config', 'user.email', 'test@example.com')
            (upstream/'README').write_text('first')
            git('-C', str(upstream), 'add', '.')
            git('-C', str(upstream), 'commit', '-qm', 'first')
            git('-C', str(upstream), 'checkout', '-qb', 'feature')
            (upstream/'README').write_text('feature')
            git('-C', str(upstream), 'commit', '-qam', 'feature')
            workspace = root/'workspace'
            workspace.mkdir()
            script = root/'clone.sh'
            script.write_text(Path('kits/github-clone/clone.sh').read_text().replace('dir=/home/agent/workspace', 'dir='+str(workspace)))
            bin = root/'bin'
            bin.mkdir()
            real_git = shutil.which('git')
            (bin/'git').write_text(f'''#!/bin/sh
if [ "$1" = clone ]; then
  "{real_git}" clone --depth=1 -- "$CLONE_TEST_UPSTREAM" "$5" || exit $?
  "{real_git}" -C "$5" remote set-url origin "$4"
else
  exec "{real_git}" "$@"
fi
''')
            (bin/'git').chmod(0o700)
            env = os.environ | {'PATH':str(bin)+os.pathsep+os.environ['PATH'], 'CLONE_TEST_UPSTREAM':upstream.as_uri()}
            def run(*args): return subprocess.run(['bash',str(script),'owner/repo',*args],env=env,capture_output=True,text=True)
            result = run()
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual((workspace/'README').read_text(),'feature')
            self.assertEqual(git('-C',str(workspace),'rev-parse','--is-shallow-repository'),'true')
            self.assertEqual(git('-C',str(workspace),'rev-list','--count','HEAD'),'1')
            (workspace/'README').write_text('uncommitted work')
            result = run()
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual((workspace/'README').read_text(),'uncommitted work')
            result = run('feature','123')
            self.assertNotEqual(result.returncode,0)
            git('-C',str(workspace),'remote','set-url','origin','https://github.com/other/repo.git')
            self.assertNotEqual(run().returncode,0)

if __name__=='__main__': unittest.main()
