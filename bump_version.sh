#!/bin/bash
# Version bumping script for Ten Week Goal App
# Usage: ./bump_version.sh <version> <message>

set -e  # Exit on error

NEW_VERSION=$1
MESSAGE=$2

# Validate arguments
if [ -z "$NEW_VERSION" ] || [ -z "$MESSAGE" ]; then
    echo "❌ Error: Missing required arguments"
    echo ""
    echo "Usage: ./bump_version.sh <version> <message>"
    echo ""
    echo "Examples:"
    echo "  ./bump_version.sh 0.8.1 'Fix test suite after SQLiteData migration'"
    echo "  ./bump_version.sh 0.9.0 'Add VoiceOver accessibility support'"
    echo "  ./bump_version.sh 1.0.0 'First stable release'"
    exit 1
fi

# Validate version format (x.y.z)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Error: Invalid version format '$NEW_VERSION'"
    echo "   Expected format: MAJOR.MINOR.PATCH (e.g., 0.8.1)"
    exit 1
fi

# Show current version
CURRENT_VERSION=$(cat version.txt)
echo "Current version: $CURRENT_VERSION"
echo "New version:     $NEW_VERSION"
echo "Message:         $MESSAGE"
echo ""

# Confirm with user
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted"
    exit 1
fi

# Update version.txt
echo "$NEW_VERSION" > version.txt
echo "✓ Updated version.txt"

# Git operations
git add version.txt

# Create commit
git commit -m "chore: Bump version to $NEW_VERSION

$MESSAGE"
echo "✓ Created commit"

# Create annotated tag
git tag -a "v$NEW_VERSION" -m "v$NEW_VERSION - $MESSAGE"
echo "✓ Created tag v$NEW_VERSION"

echo ""
echo "✅ Version bumped successfully!"
echo ""
echo "Next steps:"
echo "  git log -1        # Review the commit"
echo "  git show v$NEW_VERSION  # Review the tag"
echo "  git push && git push --tags  # Publish to remote"
