# conventional-semver

A GitHub Action that calculates the next [semantic version](https://semver.org) from your git history using [Conventional Commits](https://www.conventionalcommits.org). No Node.js, no Docker — pure bash.

## Usage

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # required: full history + tags

- uses: logi-camp/conventioanl-semver@v1
  id: semver

- run: echo "Next version is ${{ steps.semver.outputs.version_tag }}"
```

> `fetch-depth: 0` is required. The default shallow clone has no tags or history, so the action cannot determine the previous version.

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `prefix` | Tag prefix | `v` |
| `default_bump` | Bump type when no conventional commits are found (`major` / `minor` / `patch` / `none`) | `patch` |
| `initial_version` | Starting version when the repo has no tags yet | `0.0.0` |
| `prerelease` | Prerelease identifier (`rc`, `alpha`, `beta`, etc.). When set, produces prerelease tags | *(empty)* |
| `prerelease_identifier` | How to generate prerelease identifier: `numbered` (rc.1, rc.2) or `sha` (rc.a1b2c3d) | `numbered` |
| `include_sha` | Append short commit SHA to tag (`auto` / `true` / `false`) | `auto` |

## Outputs

| Output | Description | Example |
|---|---|---|
| `version` | Next semantic version | `1.4.0` or `1.3.0-rc.1-a1b2c3d` or `1.3.0-rc.a1b2c3d` |
| `version_tag` | Next version with prefix | `v1.4.0` or `v1.3.0-rc.a1b2c3d` |
| `previous_version` | Previous version without prefix | `1.3.0` |
| `previous_version_tag` | Previous version tag, empty if no tags existed | `v1.3.0` |
| `base_version` | Base version without prerelease suffix or SHA | `1.4.0` |
| `base_version_tag` | Base version tag with prefix | `v1.4.0` |
| `changelog` | Markdown changelog grouped by commit type | _(see below)_ |
| `bump` | Bump type applied | `minor` |
| `last_commit` | SHA of HEAD at calculation time | `49d6690...` |
| `rc_number` | Prerelease identifier (number or SHA). Only set when `prerelease` is used | `1` or `a1b2c3d` |

## Version bump rules

| Commit pattern | Bump |
|---|---|
| `type!: …` or `type(scope)!: …` | **major** |
| `BREAKING CHANGE:` in commit body | **major** |
| `feat: …` / `feat(scope): …` | **minor** |
| `fix: …` / `fix(scope): …` | **patch** |
| `perf: …` / `perf(scope): …` | **patch** |
| anything else | value of `default_bump` input |

The highest bump found across all commits since the last tag wins (major > minor > patch).

## Changelog format

The `changelog` output is a markdown string grouped by commit type:

```markdown
## Breaking Changes
- feat!: redesign API response format

## Features
- feat: add dark mode toggle
- feat(api): add pagination support

## Bug Fixes
- fix: resolve null pointer on login

## Performance Improvements
- perf: cache database queries
```

## Pre-release versioning

Use the `prerelease` input to produce sequential pre-release tags. This is useful for release candidate (RC), alpha, or beta builds on staging/release branches.

### How it works

The algorithm differs based on the `prerelease_identifier` input:

#### Numbered (default)
1. The action computes the **base version** from conventional commits (same as normal mode).
2. It scans existing tags matching `{base_version}-{prerelease}.*` to find the highest RC number.
3. It outputs the next sequential prerelease tag.

> **Important:** For the numbered mode to correctly increment RC numbers, you must create and push the tags after each run. If tags are not pushed, the action cannot see previous RC tags and will always output `rc.1`. Use the SHA-based mode if you don't want to manage tag synchronization.

#### SHA-based
1. The action computes the **base version** from conventional commits (same as normal mode).
2. It uses the current commit's SHA as the prerelease identifier.
3. Each commit automatically gets a unique version without requiring tag tracking.

### Numbered example (requires tag pushing)

```
Last tag:     v1.2.3
Commits:      feat: new endpoint
Base version: v1.3.0
Existing RCs: v1.3.0-rc.1, v1.3.0-rc.2  ← tags must exist in repo
Output:       v1.3.0-rc.3-a1b2c3d
```

### SHA-based example

```
Last tag:     v1.2.3
Commits:      feat: new endpoint
Base version: v1.3.0
Output:       v1.3.0-rc.a1b2c3d
```

Each push to the release branch produces a unique version automatically in both modes.

### SHA suffix (numbered mode only)

When using `prerelease_identifier: numbered`, by default (`include_sha: auto`), prerelease tags include a 7-char commit SHA suffix:

```
v1.3.0-rc.1-a1b2c3d   ← with SHA suffix (default for prerelease)
v1.3.0-rc.1            ← without SHA suffix
v1.3.0                 ← final releases never include SHA (unless overridden)
```

The `include_sha` input controls this:

| Value | Behavior |
|---|---|
| `auto` | SHA included for numbered prereleases only |
| `true` | SHA always appended (including final releases) |
| `false` | SHA never appended |

Note: When using `prerelease_identifier: sha`, the commit SHA is already used as the prerelease identifier, so `include_sha` has no effect.

### Release branch workflow (SHA-based)

```yaml
name: Release Candidate

on:
  push:
    branches:
      - release/**

jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      rc_tag: ${{ steps.semver.outputs.version_tag }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: logi-camp/conventioanl-semver@v1
        id: semver
        with:
          prerelease: rc
          prerelease_identifier: sha

      - name: Print version
        run: |
          echo "RC tag: ${{ steps.semver.outputs.version_tag }}"
          echo "Base:   ${{ steps.semver.outputs.base_version }}"
          echo "SHA:    ${{ steps.semver.outputs.rc_number }}"

  build:
    runs-on: ubuntu-latest
    needs: version
    steps:
      - uses: actions/checkout@v4

      - name: Build and push image
        run: |
          docker build -t registry/app:${{ needs.version.outputs.rc_tag }} .
          docker push registry/app:${{ needs.version.outputs.rc_tag }}
```

This approach ensures each commit on a release branch gets a unique identifier without requiring tags to be pushed or tracked in the repository.

### Alpha/Beta workflow

```yaml
- uses: logi-camp/conventioanl-semver@v1
  id: semver
  with:
    prerelease: alpha
    include_sha: 'false'    # clean tags: v1.3.0-alpha.1
```

### Full release flow

```
release/** branch                    main branch
────────────────                    ────────────
push → v1.3.0-rc.a1b2c3d            (no action)
push → v1.3.0-rc.e5f6g7h            (no action)
push → v1.3.0-rc.i8j9k0l            (no action)
merge ─────────────────────────────→ v1.3.0 (final release)
```

## Full workflow example

```yaml
name: Release

on:
  push:
    branches: [main]

jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: logi-camp/conventioanl-semver@v1
        id: semver

      - name: Create tag
        if: steps.semver.outputs.bump != 'none'
        run: |
          git tag ${{ steps.semver.outputs.version_tag }}
          git push origin ${{ steps.semver.outputs.version_tag }}

      - name: Create GitHub Release
        if: steps.semver.outputs.bump != 'none'
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ steps.semver.outputs.version_tag }}
          body: ${{ steps.semver.outputs.changelog }}
```
