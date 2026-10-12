#!/usr/bin/env python3
"""Local publication checks. Reports categories, never matched private values."""
import argparse
import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys


def git(*args, data=None):
    return subprocess.check_output(['git', '--no-replace-objects', *args], input=data, stderr=subprocess.PIPE)


EMAIL = re.compile(rb'[A-Za-z0-9.!#$%&*+/=?^_{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}')
HOME = re.compile(rb'/(?:Users|home)/[A-Za-z0-9_.-]+/|/(?:private/)?var/folders/[A-Za-z0-9/_.-]+')
SECRET = re.compile(rb'-----BEGIN (?:RSA |EC |DSA |OPENSSH |ENCRYPTED )?PRIVATE KEY-----|-----BEGIN PGP PRIVATE' rb' KEY BLOCK-----|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{24,}')
ASSIGNMENT = re.compile(rb'(?i)(?:password|api[_-]?key|access[_-]?token|secret)\s*[=:]\s*["\x27]([^"\x27\n]{16,})["\x27]')
PRIVATE_PARTS = {'.build', '.swiftpm', 'dist', 'work', 'private', 'local-only', 'logs', 'diagnostics', 'captures', 'screenshots', 'xcuserdata', '.git', '.claude', '.codex', '.idea', '.vscode'}
PRIVATE_SUFFIXES = {'.p12', '.p8', '.pem', '.key', '.pfx', '.cer', '.mobileprovision', '.provisionprofile', '.keychain', '.keychain-db', '.log', '.ips', '.crash', '.zip', '.dmg', '.sqlite', '.sqlite3', '.db', '.xccheckout', '.xcuserstate'}


# Visually reviewed artwork, exported only from the repository's vector sources.
# Changed bytes or another path require a new review. Other content checks still run.
REVIEWED_BINARY_ASSETS = {
    'Resources/AppIcon.icns': {'6b5ae4da162bd95a73f6f830b36ebb016caf4b38e7a51798e2f4dbcb7a1e908c'},
}


def public_email(value, identity=False):
    value = value.lower()
    if value.endswith(b'@users.noreply.github.com') or value == b'noreply@github.com':
        return True
    if identity:
        return False
    domain = value.rsplit(b'@', 1)[-1]
    return domain in {b'example.com', b'example.org', b'example.net'} or domain.endswith((b'.invalid', b'.example', b'.test'))


def path_private(name):
    p = PurePosixPath(name.lower())
    return bool(set(p.parts) & PRIVATE_PARTS or p.suffix in PRIVATE_SUFFIXES or
                any(part.endswith(('.app', '.dsym', '.xcuserdatad')) for part in p.parts) or
                p.name == '.ds_store' or p.name.startswith(('.env', 'codex-clipboard', 'screenshot', 'screen shot')))


def scan_content(data):
    findings = set()
    if b'\0' in data:
        findings.add('binary file needs explicit publication review')
    if HOME.search(data):
        findings.add('absolute personal-machine path')
    if SECRET.search(data) or ASSIGNMENT.search(data):
        findings.add('possible credential')
    if any(not public_email(m.group()) for m in EMAIL.finditer(data)):
        findings.add('non-public email address')
    return findings


def check(refs, worktree=True, publication_names=()):
    findings = set()
    seen = set()
    # Grafts can hide parents from rev-list. Block instead of trusting a local view.
    graft = Path(os.environ.get('GIT_GRAFT_FILE') or
                 os.fsdecode(git('rev-parse', '--git-path', 'info/grafts').strip()))
    if graft.is_file() and graft.read_bytes().strip():
        findings.add('local history grafts prevent complete publication review')
    def inspect(name, data, mode=b'100644'):
        # Do not echo filenames: they can themselves contain personal information.
        if path_private(name):
            findings.add('private or generated file is eligible for publication')
        if mode in {b'120000', b'160000'}:
            findings.add('symlink or submodule needs explicit publication review')
        findings.update(scan_content(os.fsencode(name)))
        content_findings = scan_content(data)
        if hashlib.sha256(data).hexdigest() in REVIEWED_BINARY_ASSETS.get(name, set()):
            content_findings.discard('binary file needs explicit publication review')
        findings.update(content_findings)

    for ref in [*refs, *publication_names]:
        findings.update(scan_content(os.fsencode(ref)))
    commits = git('rev-list', *refs).decode().splitlines() if refs else []
    if commits and git('rev-parse', '--is-shallow-repository').strip() == b'true':
        findings.add('history is shallow; fetch full history before checking')
    for commit in commits:
        raw = git('cat-file', 'commit', commit)
        header, _, message = raw.partition(b'\n\n')
        findings.update(scan_content(raw))
        for line in header.splitlines():
            if line.startswith((b'author ', b'committer ')):
                match = re.search(rb'<([^<>]+)>', line)
                if not match or not public_email(match[1], identity=True):
                    findings.add('commit author or committer needs a GitHub no-reply address')
        for entry in git('ls-tree', '-rz', commit).split(b'\0'):
            if not entry:
                continue
            metadata, name = entry.split(b'\t', 1)
            mode, kind, oid = metadata.split()
            if kind != b'blob':
                findings.add('submodule needs explicit publication review')
                continue
            key = (name, oid)
            if key not in seen:
                seen.add(key)
                inspect(os.fsdecode(name), git('cat-file', 'blob', oid.decode()), mode)

    # Include annotated tag messages and tagger identity; they are public metadata too.
    tags_seen = set()
    for ref in refs:
        while git('cat-file', '-t', ref).strip() == b'tag' and ref not in tags_seen:
            tags_seen.add(ref)
            tag = git('cat-file', 'tag', ref)
            findings.update(scan_content(tag))
            header = tag.partition(b'\n\n')[0]
            for line in header.splitlines():
                if line.startswith(b'tagger '):
                    match = re.search(rb'<([^<>]+)>', line)
                    if not match or not public_email(match[1], identity=True):
                        findings.add('tagger needs a GitHub no-reply address')
            target = re.search(rb'^object ([a-f0-9]+)$', header, re.M)
            if not target:
                raise ValueError('invalid tag')
            ref = target[1].decode()

    if worktree:
        # Read the index separately: a fixed working copy can conceal a staged leak.
        for entry in git('ls-files', '-sz').split(b'\0'):
            if not entry:
                continue
            metadata, name = entry.split(b'\t', 1)
            mode, oid, stage = metadata.split()
            if mode == b'160000':
                findings.add('submodule needs explicit publication review')
                continue
            inspect(os.fsdecode(name), git('cat-file', 'blob', oid.decode()), mode)
        names = set(git('ls-files', '-z', '--cached', '--others', '--exclude-standard').split(b'\0'))
        for name in names - {b''}:
            path = Path(os.fsdecode(name))
            if path.is_symlink():
                inspect(os.fsdecode(name), os.fsencode(os.readlink(path)), b'120000')
            elif path.is_file():
                inspect(os.fsdecode(name), path.read_bytes())
    return findings, len(commits), len(seen)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pre-push', action='store_true')
    args = parser.parse_args()
    os.chdir(os.fsdecode(git('rev-parse', '--show-toplevel').strip()))
    refs = git('for-each-ref', '--format=%(refname)').decode().splitlines()
    publication_names = []
    if args.pre_push:
        # Include the actual pushed object, even for a detached HEAD or raw SHA push.
        for line in sys.stdin:
            fields = line.split()
            if len(fields) != 4:
                raise ValueError('invalid push input')
            oid = fields[1]
            if set(oid) != {'0'}:
                if not re.fullmatch(r'[a-fA-F0-9]{40,64}', oid):
                    raise ValueError('invalid object')
                refs.append(oid)
                # A refspec can publish a new remote name absent from local refs.
                publication_names.append(fields[2])
    # A detached HEAD may be missing from for-each-ref even when branches exist.
    try:
        refs.append(git('rev-parse', '--verify', '-q', 'HEAD').decode().strip())
    except subprocess.CalledProcessError:
        pass  # Unborn repository: still inspect the index and working files.
    findings, commits, blobs = check(refs, publication_names=publication_names)
    if findings:
        print('Publication privacy check failed. No content or matched values are printed.')
        for finding in sorted(findings):
            print('- ' + finding)
        return 1
    print(f'Publication privacy check passed: {commits} commits, {blobs} historical file versions, index and nonignored files checked.')
    print('Pattern checks cannot identify every secret or personal detail. Review screenshots and the final diff manually.')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, subprocess.CalledProcessError):
        print('Publication privacy check could not complete; push blocked. Check Git state locally.', file=sys.stderr)
        sys.exit(1)
