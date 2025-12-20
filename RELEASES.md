# Releases

## 100.0.0 (2025-12-20)

Initial versioned release of the yunacaba/STTextView fork.

### Features
- Added `bottomPadding` property for scroll-past-end behavior (iOS and macOS)
- Added `rightPadding` property for accessory view spacing (macOS)
- Custom fork maintained for story-builder project

### Version Scheme
- All versions in this fork are yunacaba-specific (independent from upstream)
- Semantic versioning: MAJOR.MINOR.PATCH
- story-builder pins to exact versions for build stability

---

## Upcoming Releases

Use this section to plan upcoming versions:

### 100.1.0 (Planned)
- TBD based on story-builder feature requirements

---

## Release Checklist

Before creating a new release:

1. [ ] All changes merged to `main` branch
2. [ ] Integration tests pass in story-builder CI
3. [ ] Version number determined (MAJOR.MINOR.PATCH)
4. [ ] Tag created and pushed: `git tag X.Y.Z && git push origin X.Y.Z`
5. [ ] This file updated with release notes
6. [ ] story-builder updated to new version
