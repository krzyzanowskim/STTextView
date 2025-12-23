# STTextView Fork - Development Guide

**IMPORTANT:** This is a public repository. Do not reference private repositories, proprietary project names, or non-public technologies in documentation or commits.

This is a fork of [STTextView](https://github.com/krzyzanowskim/STTextView) maintained by yunacaba with additional features.

---

## ⛔ CRITICAL RULES - READ FIRST

### 1. NEVER Push Directly to Main

**ALWAYS create a PR first.** No exceptions.

```bash
# ❌ NEVER DO THIS
git checkout main
git commit -m "some change"
git push origin main

# ✅ ALWAYS DO THIS
git checkout -b fix/description-of-change
git commit -m "fix: description"
git push -u origin fix/description-of-change
gh pr create --repo yunacaba/STTextView --title "fix: description" --body "..."
# Wait for PR to be reviewed and merged
```

### 2. NEVER Auto-Apply Git Tags

**NEVER run `git tag` and `git push origin <tag>` automatically.** Instead, after a PR is merged, provide the tagging commands for the user to run manually.

```bash
# ❌ NEVER DO THIS AUTOMATICALLY
git tag 100.2.2
git push origin 100.2.2

# ✅ ALWAYS DO THIS - Provide commands for user to run:
echo "PR merged. To create the release tag, run:"
echo "  git checkout main && git pull"
echo "  git tag 100.2.2"
echo "  git push origin 100.2.2"
```

**Why?** Overwriting git tags breaks SPM package resolution. Once a tag is pushed, changing it causes checksum mismatches in downstream projects. Let the user verify and apply tags manually.

---

## Custom Features

This fork adds custom properties not available in the upstream version:
- **`bottomPadding`** - Controls scroll-past-end behavior (iOS and macOS)

These properties are maintained for compatibility with downstream projects.

## Versioning Scheme

**Format:** `MAJOR.MINOR.PATCH` (standard semantic versioning)

- **All versions** in this fork are yunacaba-specific (not upstream)
- **Semantic versioning** - Breaking changes, new features, bug fixes
- **Examples:** `100.0.0`, `100.1.0`, `101.0.0`
- **Note:** The yunacaba fork maintains independent version numbers from upstream STTextView

**Why 100.x.x?** Starting at version 100.0.0 avoids collisions with upstream versions (currently at 0.9.6) while maintaining SPM compatibility.

### Version Bump Guidelines

**PATCH** (100.0.0 → 100.0.1):
- Bug fixes only
- No API changes
- No new features
- Example: Fix crash in `bottomPadding` calculation

**MINOR** (100.0.0 → 100.1.0):
- New features
- Backward-compatible API additions
- Example: Add new `topPadding` property

**MAJOR** (100.1.0 → 101.0.0):
- Breaking API changes
- Remove or rename public APIs
- Change behavior of existing APIs
- Example: Rename `bottomPadding` to `contentBottomPadding`

## Branch Strategy

- **`main`** - Integration branch, always stable, releases are tagged here
- **`yuna/*` or `feature/*`** - Feature branches for all development work
- **Tags** - Releases (e.g., `100.0.0`, `100.1.0`)

**Note:** We do NOT use a `dev` branch. All work happens on dedicated feature branches.

### Development Workflow

**Standard flow (all changes):**
1. Create a feature branch from `main`: `git checkout -b yuna/feature-name main`
2. Develop and test locally with downstream projects using path-based dependencies
3. When ready, create a Pull Request to merge into `main`
4. After PR review/approval, merge to `main`
5. Create release tag on `main`
6. Update downstream projects to new version

**Why feature branches instead of dev?**
- Each feature/fix is isolated and can be reviewed independently
- No risk of accidentally pushing incomplete work to a shared branch
- PRs provide clear review points before merging to main
- Easy to abandon or delay work without affecting other changes

See "Handling Concurrent Changes" section below for details.

## Release Process

### Manual Release (Standard)

1. **Ensure main is stable:**
   ```bash
   git checkout main
   git pull
   ```

2. **Determine version number:**
   - Review commits since last release: `git log 99.0.0..HEAD --oneline`
   - Check for API changes in commit diffs
   - Decide MAJOR.MINOR.PATCH bump based on changes

3. **Create and push tag:**
   ```bash
   git tag 100.0.0
   git push origin 100.0.0
   ```

4. **Update `RELEASES.md`** (see below)

### Automated Version Detection (Claude Code)

**When Claude Code creates a release, it will:**

1. **Analyze changes** since last release:
   - Scan commit messages for keywords: "breaking", "feat", "fix"
   - Check public API changes (new/removed/modified declarations)
   - Examine test changes for behavioral differences

2. **Determine version bump:**
   - **MAJOR** if any of:
     - Breaking change keywords in commits
     - Public API removed or signature changed
     - `@available` deprecations removed
   - **MINOR** if any of:
     - New public properties/methods added
     - New features in commit messages
     - Backward-compatible API additions
   - **PATCH** otherwise:
     - Bug fixes only
     - Internal refactoring
     - Documentation updates

3. **Create release tag:**
   - Format: `MAJOR.MINOR.PATCH`
   - Push tag to remote
   - Document decision in release notes

4. **Example decision process:**
   ```
   Changes since 99.0.0:
   - Added `topPadding` property (public API addition)
   - Fixed crash in bottomPadding calculation
   - Updated documentation

   Decision: MINOR bump (new public API)
   New version: 100.0.0
   ```

### Integration Testing Before Release

Before creating any release tag, run integration tests in downstream projects to ensure compatibility.

## Handling Concurrent Changes

### Creating Feature Branches

All work happens on feature branches. Multiple features can be developed in parallel:

```bash
# Feature A
git checkout -b yuna/text-selection main

# Feature B (separate branch)
git checkout -b yuna/undo-redo main
```

### Testing Feature Branches

In downstream projects, use path-based dependencies for fast iteration:
```swift
// Local path (recommended for development)
.package(path: "../../../STTextView")  // Adjust path as needed

// Or branch-based for CI testing
.package(url: "https://github.com/yunacaba/STTextView", branch: "yuna/text-selection")
```

**Important:** Always revert to version pin before merging downstream changes.

### Release Strategy for Concurrent Features

**Sequential (typical):**
- Merge Feature A PR → Release 100.1.0
- Merge Feature B PR → Release 100.2.0

**Combined (if features are related):**
- Merge both PRs to main → Tag 100.1.0

## Local Development with Downstream Projects

**Path-based dependency** for fast iteration:

```bash
# In downstream project Package.swift
.package(path: "../../../STTextView")

# Make changes in STTextView
# Test immediately in downstream project without tags/commits
```

**Important:** Revert to version pin before committing downstream changes.

## Upstream Sync

Periodically sync with upstream STTextView:

```bash
# Add upstream if not already added
git remote add upstream https://github.com/krzyzanowskim/STTextView.git

# Fetch upstream changes
git fetch upstream

# Review changes
git log HEAD..upstream/main --oneline

# Merge upstream (creates merge commit)
git checkout main
git merge upstream/main

# Or rebase (cleaner history, but requires force push)
git rebase upstream/main

# Test thoroughly with downstream projects
# Create new release if successful
```

## Critical Dependencies

Downstream projects depend on these custom properties:
- `bottomPadding` - **Must not be removed or renamed**

**Before any major refactoring:**
1. Search for usages in downstream projects
2. Coordinate API changes with downstream updates
3. Consider deprecation path for breaking changes

## License

This fork maintains the GPL v3 license of the original STTextView project.
