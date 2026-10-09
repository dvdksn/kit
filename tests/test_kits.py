from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parent.parent
# The workload is published separately from the mixins.
WORKLOAD = 'shell'


def kit_dirs():
    return {p.name for p in (ROOT / 'kits').iterdir() if p.is_dir()}


def bake_mixins():
    hcl = (ROOT / 'docker-bake.hcl').read_text()
    block = re.search(r'variable "MIXINS" \{.*?default = \[(.*?)\]', hcl, re.S)
    return set(re.findall(r'"([^"]+)"', block.group(1)))


def env_kits():
    env = (ROOT / 'sbxenv.yaml').read_text()
    return set(re.findall(r'source: ghcr\.io/[^/]+/kit-([\w-]+):', env))


class KitRegistration(unittest.TestCase):
    def test_every_kit_has_a_descriptor(self):
        for kit in kit_dirs():
            self.assertTrue((ROOT / 'kits' / kit / f'{kit}.yaml').is_file(), kit)

    def test_bake_publishes_every_mixin(self):
        self.assertEqual(kit_dirs() - {WORKLOAD}, bake_mixins(),
                         'MIXINS in docker-bake.hcl must match the directories in kits/')

    def test_env_composes_every_kit(self):
        self.assertEqual(kit_dirs(), env_kits(),
                         'sbxenv.yaml must list every kit in kits/')


if __name__ == '__main__':
    unittest.main()
