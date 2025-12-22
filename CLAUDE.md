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

- **`dev`** - Active development, fast iteration
- **`feature/*`** - Long-running parallel features (rare)
- **`main`** - Integration branch, always stable
- **Tags** - Releases (e.g., `100.0.0`, `100.1.0`)

### Development Workflow

**Standard flow (most changes):**
1. Work on `dev` branch
2. Test locally with downstream projects using path-based dependencies
3. When ready, merge `dev` → `main`
4. Create integration test PR in downstream projects
5. If tests pass, create release tag
6. Update downstream projects to new version

**Concurrent features (rare):**
1. Create feature branch: `feature/descriptive-name`
2. Develop and test independently
3. Merge to `main` when ready
4. Create release tag

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

When working on multiple features in parallel:

```bash
# Feature A
git checkout -b feature/text-selection main

# Feature B (separate branch)
git checkout -b feature/undo-redo main
```

### Testing Feature Branches

In downstream projects, use branch-based or path-based dependencies:
```swift
// Option 1: Branch-based
.package(url: "https://github.com/yunacaba/STTextView", branch: "feature/text-selection")

// Option 2: Local path (faster iteration)
.package(path: "../../../STTextView")  // Adjust path as needed
```

### Release Strategy for Concurrent Features

**Sequential (recommended for rare concurrent work):**
- Finish Feature A → Release 100.0.0
- Then Feature B → Release 100.1.0

**Cherry-pick:**
- Feature A ready → Cherry-pick to main → Tag 100.0.0
- Feature B ready → Cherry-pick to main → Tag 100.1.0

**Combined:**
- Merge both to main → Tag 100.1.0

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
