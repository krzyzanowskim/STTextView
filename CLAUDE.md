# STTextView Fork - Development Guide

This is a fork of [STTextView](https://github.com/krzyzanowskim/STTextView) maintained for the story-builder project.

## Custom Features

This fork adds custom properties not available in the upstream version:
- **`bottomPadding`** - Controls scroll-past-end behavior (iOS and macOS)
- **`rightPadding`** - Controls right margin space for accessory views (macOS)

These properties are required by story-builder and must be maintained across updates.

## Versioning Scheme

**Format:** `MAJOR.MINOR.PATCH` (standard semantic versioning)

- **All versions** in this fork are yunacaba-specific (not upstream)
- **Semantic versioning** - Breaking changes, new features, bug fixes
- **Examples:** `100.0.0`, `100.1.0`, `101.0.0`
- **Note:** The yunacaba fork maintains independent version numbers from upstream STTextView

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
2. Test locally with story-builder using path-based dependency
3. When ready, merge `dev` → `main`
4. Create integration test PR in story-builder
5. If tests pass, create release tag
6. Update story-builder to new version

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

Before creating any release tag, run integration tests:

1. **Create integration test branch in story-builder:**
   ```bash
   cd /Users/yuna/src/yunacaba/story-builder
   git checkout -b test/sttv-integration-100.0.0

   # Update Package.swift to point to main branch
   # Edit apple/Packages/Snout/Package.swift:
   .package(url: "https://github.com/yunacaba/STTextView", branch: "main")

   git commit -am "test: Integration test for STTextView 100.0.0"
   git push origin test/sttv-integration-100.0.0
   ```

2. **Let CI validate**
3. **If CI passes** → Create release tag in STTextView
4. **If CI fails** → Fix issues, update main, test again

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

In story-builder:
```swift
// Option 1: Branch-based
.package(url: "https://github.com/yunacaba/STTextView", branch: "feature/text-selection")

// Option 2: Local path (faster iteration)
.package(path: "../../../../STTextView")  // Ensure STTextView is on correct branch
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

## Local Development with story-builder

**Path-based dependency** for fast iteration:

```bash
# In story-builder/apple/Packages/Snout/Package.swift
.package(path: "../../../../STTextView")

# Make changes in STTextView
# Test immediately in story-builder without tags/commits
cd /Users/yuna/src/yunacaba/story-builder/apple
task test-snout
task test-app
```

**Important:** Revert to exact version pin before committing story-builder changes.

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

# Test thoroughly with story-builder
# Create new release if successful
```

## Critical Dependencies

story-builder depends on these custom properties:
- `bottomPadding` - **Must not be removed or renamed**
- `rightPadding` - **Must not be removed or renamed**

**Before any major refactoring:**
1. Search for usages in story-builder
2. Coordinate API changes with story-builder updates
3. Consider deprecation path for breaking changes

## License

This fork maintains the GPL v3 license of the original STTextView project.
