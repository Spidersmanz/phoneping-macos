#!/usr/bin/env python3
"""Exercise publication failures in disposable repositories with invented data."""
import importlib.util
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

script = Path(__file__).with_name('check-privacy.py')
spec = importlib.util.spec_from_file_location('privacy', script)
privacy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(privacy)
PUBLIC_EMAIL = '12345+test-maintainer@users.noreply.github.com'
PRIVATE_EMAIL = 'fictional-user' + '@' + 'mail' + '.com'
SYNTHETIC_TOKEN = 'ghp_' + 'X' * 36


class PrivacyTests(unittest.TestCase):
    def setUp(self):
        self.previous = Path.cwd()
        self.temp = tempfile.TemporaryDirectory()
        os.chdir(self.temp.name)
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'test-maintainer')
        self.git('config', 'user.email', PUBLIC_EMAIL)
        self.git('config', 'commit.gpgsign', 'false')
        self.git('config', 'tag.gpgsign', 'false')
        self.git('config', 'core.hooksPath', '/dev/null')
        Path('README.md').write_text('Fictional test repository.\n')
        self.commit()

    def tearDown(self):
        os.chdir(self.previous)
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', *args], stderr=subprocess.PIPE)

    def commit(self):
        self.git('add', '-A')
        self.git('commit', '-qm', 'Synthetic fixture')

    def findings(self):
        refs = self.git('for-each-ref', '--format=%(refname)').decode().splitlines()
        return privacy.check(refs)[0]

    def testCleanSourcePasses(self):
        Path('fixture.txt').write_text('sample@example.invalid')
        self.assertEqual(self.findings(), set())

    def testPersonalCommitIdentityFails(self):
        self.git('config', 'user.email', PRIVATE_EMAIL)
        self.git('commit', '--amend', '--reset-author', '--no-edit', '-q')
        self.assertIn('commit author or committer needs a GitHub no-reply address', self.findings())

    def testDeletedHistoricalPrivateDataFails(self):
        Path('notes.txt').write_text(PRIVATE_EMAIL)
        self.commit()
        Path('notes.txt').unlink()
        self.commit()
        self.assertIn('non-public email address', self.findings())

    def testCleanWorkingCopyCannotHideStagedSecret(self):
        Path('fixture.txt').write_text(SYNTHETIC_TOKEN)
        self.git('add', 'fixture.txt')
        Path('fixture.txt').write_text('Clean working copy')
        self.assertIn('possible credential', self.findings())

    def testIgnoredLocalDataIsExcludedButForcedAddFails(self):
        Path('.gitignore').write_text('.env\n')
        Path('.env').write_text(PRIVATE_EMAIL)
        self.assertEqual(self.findings(), set())
        self.git('add', '-f', '.env')
        self.assertIn('private or generated file is eligible for publication', self.findings())

    def testBinaryCaptureRequiresReview(self):
        Path('image.png').write_bytes(b'PNG\0synthetic')
        self.assertIn('binary file needs explicit publication review', self.findings())

    def reviewed_asset(self, data):
        name = 'Resources/AppIcon.icns'
        Path('Resources').mkdir(exist_ok=True)
        Path(name).write_bytes(data)
        return patch.dict(privacy.REVIEWED_BINARY_ASSETS, {name: {hashlib.sha256(data).hexdigest()}}, clear=True)

    def testReviewedArtworkPassesOnlyAtItsExactPathIncludingHistory(self):
        data = b'icns\0fictional artwork'
        with self.reviewed_asset(data):
            self.commit()
            self.assertEqual(self.findings(), set())
            Path('another.icns').write_bytes(data)
            self.assertIn('binary file needs explicit publication review', self.findings())

    def testChangedArtworkRequiresAnotherReview(self):
        data = b'icns\0fictional artwork'
        with self.reviewed_asset(data):
            Path('Resources/AppIcon.icns').write_bytes(data + b'changed')
            self.assertIn('binary file needs explicit publication review', self.findings())

    def testCleanArtworkCannotHideAnUnreviewedStagedVersion(self):
        data = b'icns\0fictional artwork'
        with self.reviewed_asset(data):
            Path('Resources/AppIcon.icns').write_bytes(data + b'changed')
            self.git('add', 'Resources/AppIcon.icns')
            Path('Resources/AppIcon.icns').write_bytes(data)
            self.assertIn('binary file needs explicit publication review', self.findings())

    def testReviewedArtworkStillRunsPrivateContentChecks(self):
        data = b'icns\0' + PRIVATE_EMAIL.encode()
        with self.reviewed_asset(data):
            self.assertIn('non-public email address', self.findings())

    def testSymlinkIsNotFollowed(self):
        Path('outside').symlink_to('/does-not-exist/fictional-private-file')
        self.assertIn('symlink or submodule needs explicit publication review', self.findings())

    def testPrivateFilenameFailsWithoutExposingTheName(self):
        Path(PRIVATE_EMAIL + ".txt").write_text("Otherwise harmless text")
        self.assertIn("non-public email address", self.findings())

    def testAbsoluteMachinePathFails(self):
        Path('fixture.txt').write_text('/' + 'Users/' + 'fictional-user/project')
        self.assertIn('absolute personal-machine path', self.findings())

    def testAnnotatedTagIdentityFails(self):
        self.git('-c', 'user.email=' + PRIVATE_EMAIL, 'tag', '-a', 'preview', '-m', 'Synthetic tag')
        self.assertIn('tagger needs a GitHub no-reply address', self.findings())

    def testPrivateCommitMessageFails(self):
        self.git('commit', '--allow-empty', '-qm', PRIVATE_EMAIL)
        self.assertIn('non-public email address', self.findings())

    def testPushOfOtherwiseUnreachableCommitIsChecked(self):
        clean = self.git('rev-parse', 'HEAD').decode().strip()
        Path('fixture.txt').write_text(SYNTHETIC_TOKEN)
        self.commit()
        private = self.git('rev-parse', 'HEAD').decode().strip()
        self.git('reset', '--hard', clean)
        result = subprocess.run([sys.executable, str(script), '--pre-push'],
                                input=f'{private} {private} refs/heads/test {"0" * 40}\n',
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('possible credential', result.stdout)
        self.assertNotIn(SYNTHETIC_TOKEN, result.stdout + result.stderr)


    def testPushDestinationNameIsCheckedWithoutPrintingIt(self):
        oid = self.git('rev-parse', 'HEAD').decode().strip()
        destination = 'refs/heads/' + PRIVATE_EMAIL
        result = subprocess.run([sys.executable, str(script), '--pre-push'],
                                input=f'refs/heads/main {oid} {destination} {"0" * 40}\n',
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('non-public email address', result.stdout)
        self.assertNotIn(PRIVATE_EMAIL, result.stdout + result.stderr)

    def testReplacementCannotHideOriginalPrivateCommit(self):
        clean = self.git('rev-parse', 'HEAD').decode().strip()
        Path('fixture.txt').write_text(SYNTHETIC_TOKEN)
        self.commit()
        original = self.git('rev-parse', 'HEAD').decode().strip()
        self.git('replace', original, clean)
        # Even the staged and visible trees are clean; only the real object leaks.
        Path('fixture.txt').unlink()
        self.git('add', '-A')
        self.assertIn('possible credential', self.findings())

    def testGraftCannotHidePrivateParent(self):
        Path('fixture.txt').write_text(SYNTHETIC_TOKEN)
        self.commit()
        Path('fixture.txt').unlink()
        self.commit()
        head = self.git('rev-parse', 'HEAD').decode().strip()
        Path('.git/info/grafts').write_text(head + '\n')
        self.assertIn('local history grafts prevent complete publication review', self.findings())

    def testDetachedHeadIsCheckedAlongsideOtherRefs(self):
        self.git('checkout', '--detach', '-q')
        Path('fixture.txt').write_text(SYNTHETIC_TOKEN)
        self.commit()
        Path('fixture.txt').unlink()
        self.commit()
        result = subprocess.run([sys.executable, str(script)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('possible credential', result.stdout)
        self.assertNotIn(SYNTHETIC_TOKEN, result.stdout + result.stderr)


    def testExternalGraftAlsoBlocksReview(self):
        graft = Path(self.temp.name) / 'synthetic-grafts'
        graft.write_text(self.git('rev-parse', 'HEAD').decode())
        with patch.dict(os.environ, {'GIT_GRAFT_FILE': str(graft)}):
            self.assertIn('local history grafts prevent complete publication review', self.findings())

    def testUnbornRepositoryStillChecksUncommittedContent(self):
        self.git('update-ref', '-d', 'refs/heads/main')
        Path('fixture.txt').write_text(SYNTHETIC_TOKEN)
        result = subprocess.run([sys.executable, str(script)], text=True, capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn('possible credential', result.stdout)
        self.assertNotIn(SYNTHETIC_TOKEN, result.stdout + result.stderr)

    def testDeletingPrivateRemoteNameDoesNotBlockRemoval(self):
        oid = self.git('rev-parse', 'HEAD').decode().strip()
        result = subprocess.run([sys.executable, str(script), '--pre-push'],
                                input=f'(delete) {"0" * 40} refs/heads/{PRIVATE_EMAIL} {oid}\n',
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0)
        self.assertNotIn(PRIVATE_EMAIL, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
