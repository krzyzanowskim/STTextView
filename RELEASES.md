# Releases

## 100.0.0 (2025-12-20)

Initial versioned release of the yunacaba/STTextView fork.

### Features
- Added `bottomPadding` property for scroll-past-end behavior (iOS and macOS)
- Added `rightPadding` property for accessory view spacing (macOS)
- Custom fork maintained by yunacaba

### Version Scheme
- All versions in this fork are yunacaba-specific (independent from upstream)
- Semantic versioning: MAJOR.MINOR.PATCH
- Downstream projects pin to exact versions for build stability

---

## Upcoming Releases

Use this section to plan upcoming versions:

### 100.1.0 (Planned)
- TBD based on downstream project requirements

---

## Release Checklist

Before creating a new release:

1. [ ] All changes merged to `main` branch
2. [ ] Integration tests pass in downstream project CI
3. [ ] Version number determined (MAJOR.MINOR.PATCH)
4. [ ] Tag created and pushed: `git tag X.Y.Z && git push origin X.Y.Z`
5. [ ] This file updated with release notes
6. [ ] Downstream projects updated to new version
