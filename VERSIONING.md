# Versioning Strategy

**Current Version:** 0.5.0-rearchitecture (Swift implementation - foundation laid, major rearchitecture in progress)

⚠️ **DOCUMENTATION FREEZE**: Most documentation is out of sync with reality. See `DOCUMENTATION_INCONSISTENCIES.md` for details. Documentation will be updated after rearchitecture completes (~0.6.0-0.7.0).

## Version History

| Version | Date | Milestone | Notes |
|---------|------|-----------|-------|
| 0.2.0 | - | Git history begins | Python implementation starts |
| 0.2.5 | - | Flask deployment | Python Flask API deployed |
| 0.3.0 | - | Swift journey begins | Initial Swift project setup |
| **0.5.0** | **2025-10-25** | **Foundation complete, rearchitecture needed** | SQLiteData working, protocols defined, but needs structural rethink |

## Current Implementation Focus

**Active:** Swift (iOS 26+ / macOS 26+)
**On Hold:** Python backend

The two implementations have diverged significantly and **no longer share a database**.

## Swift Milestones (v0.5.0 Honest Assessment)

### ✅ Proven Concepts
- SQLiteData integration works (@Table, @Column decorators)
- Protocol system compiles (temporal separation: Completable/Doable)
- Basic SwiftUI views functional (can test on phone)
- Database operations confirmed working

### ⚠️ Needs Rearchitecture
- **Data structures**: Too many optionals, dictionary→array conversion pain
- **Protocol system**: 9 protocols - unclear if solving problems or adding ceremony
- **SwiftUI integration**: Struct ↔ @State conversion is awkward
- **Design language**: Minimal/immature - no visual identity defined
- **Generalization**: Goal/Milestone separation might be over-engineered

### ❌ Not Started (Critical for 1.0)
- Design language definition (visual identity, component library)
- Accessibility (VoiceOver labels) - **CRITICAL**
- Dynamic Type support (migrate from custom zoom)
- Platform integrations (AppIntents, EventKit)
- Test suite (broken after database migration)

## Path to 1.0 (Revised - Acknowledges Rearchitecture)

```
0.5.0 - Current state (foundation works, needs rethink)
0.6.0 - Data structure simplification (fewer optionals, remove unnecessary protocols)
0.6.5 - SwiftUI integration patterns (ViewModels or better struct shapes)
0.7.0 - Design language defined (visual identity, component library)
0.7.5 - Accessibility foundation (VoiceOver labels, Dynamic Type)
0.8.0 - Platform integrations (AppIntents OR EventKit - pick one)
0.9.0 - Test suite complete, documentation current
1.0.0 - First stable release (Swift only)
```

**Estimated Time to 1.0**: 25-40 hours (accounting for rearchitecture)


- First stable release
- **Criteria for 1.0:**
  - ✅ All tests passing
  - ✅ Accessibility complete (VoiceOver support)
  - ✅ Documentation up-to-date
  - ✅ At least one platform integration (AppIntents OR EventKit)
  - ✅ App Store ready

### When to bump MAJOR (1.0.0 → 2.0.0)
- Breaking changes (database schema changes)
- Major architectural rewrites
- Removing deprecated features

## Single Source of Truth

**File:** `version.txt` (project root)
**Content:** Plain text version number (e.g., `0.8.0`)

**Python reads from:** `python/version.py` → reads `../version.txt`
**Swift reads from:** `swift/Sources/App/Version.swift` → reads version.txt

## Bump Version Script

```bash
#!/bin/bash
# Usage: ./bump_version.sh 0.8.1 "Fix test suite after SQLiteData migration"

NEW_VERSION=$1
MESSAGE=$2

if [ -z "$NEW_VERSION" ] || [ -z "$MESSAGE" ]; then
    echo "Usage: ./bump_version.sh <version> <message>"
    echo "Example: ./bump_version.sh 0.8.1 'Fix test suite'"
    exit 1
fi

# Update version.txt
echo "$NEW_VERSION" > version.txt

# Git commit and tag
git add version.txt
git commit -m "chore: Bump version to $NEW_VERSION

$MESSAGE"
git tag -a "v$NEW_VERSION" -m "v$NEW_VERSION - $MESSAGE"

echo "✓ Version bumped to $NEW_VERSION"
echo "Run 'git push && git push --tags' to publish"
```

## Current Status Summary

**Swift Implementation:** ~50% complete (honest assessment)
- Foundation proven: ✅ (SQLiteData, protocols compile, views work)
- Data architecture: ⚠️ Needs simplification
- Design language: ❌ Not defined
- Accessibility: ❌ Not started
- Platform features: ❌ Not started
- Testing: ⚠️ Broken (fixable)

**Python Implementation:** On hold
- Last stable: 0.2.5 (Flask deployment)
- Not actively developed

**Estimated time to 1.0:** 25-40 hours (revised upward)
- Rearchitecture (data + protocols): 8-12 hours
- Design language definition: 4-6 hours
- Component library: 4-6 hours
- Accessibility: 6-8 hours
- Platform integration (1 feature): 4-6 hours
- Testing/documentation: 3-4 hours
