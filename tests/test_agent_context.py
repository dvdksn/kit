from pathlib import Path
import re
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parent.parent


def link_hook(kit):
    descriptor = (ROOT / 'kits' / kit / f'{kit}.yaml').read_text()
    commands = re.findall(r'        - command: \|\n((?:            .*\n|\n)+)', descriptor)
    return next(textwrap.dedent(command) for command in commands
                if 'target=/home/agent/.agents/AGENTS.md' in command)


class AgentContextLinks(unittest.TestCase):
    def test_links_survive_repeated_install_and_profile_updates(self):
        for kit, destination in [('codex-mixin', '.codex/AGENTS.md'),
                                 ('claude-mixin', '.claude/CLAUDE.md')]:
            with self.subTest(kit=kit), tempfile.TemporaryDirectory() as directory:
                home = Path(directory)
                profile = home / destination
                profile.parent.mkdir()
                command = link_hook(kit).replace('/home/agent', directory)
                # Install can precede the runtime's creation of the profile.
                for _ in range(2):
                    subprocess.run(['sh', '-eu', '-c', command], check=True)
                self.assertTrue(profile.is_symlink())
                target = home / '.agents/AGENTS.md'
                self.assertEqual(profile.readlink(), target)
                target.parent.mkdir()
                for content in ['initial guidance', 'updated kit index']:
                    target.write_text(content)
                    subprocess.run(['sh', '-eu', '-c', command], check=True)
                    self.assertEqual(profile.read_text(), content)

    def test_existing_instructions_and_conflicting_links_are_preserved(self):
        for kit, destination in [('codex-mixin', '.codex/AGENTS.md'),
                                 ('claude-mixin', '.claude/CLAUDE.md')]:
            for existing in ['file', 'link', 'dangling link']:
                with self.subTest(kit=kit, existing=existing), tempfile.TemporaryDirectory() as directory:
                    home = Path(directory)
                    profile = home / destination
                    profile.parent.mkdir()
                    if existing == 'file':
                        profile.write_text('user instructions')
                    else:
                        other = home / 'other.md'
                        if existing == 'link':
                            other.write_text('user instructions')
                        profile.symlink_to(other)
                    command = link_hook(kit).replace('/home/agent', directory)
                    result = subprocess.run(['sh', '-eu', '-c', command],
                                            capture_output=True, text=True)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('Refusing to replace', result.stderr)
                    if existing == 'file':
                        self.assertFalse(profile.is_symlink())
                        self.assertEqual(profile.read_text(), 'user instructions')
                    else:
                        self.assertEqual(profile.readlink(), other)
                        if existing == 'link':
                            self.assertEqual(other.read_text(), 'user instructions')


if __name__ == '__main__':
    unittest.main()
