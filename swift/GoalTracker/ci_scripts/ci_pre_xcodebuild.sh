#!/bin/sh

##
## ci_pre_xcodebuild.sh
## Xcode Cloud pre-build script
## Written by Claude Code on 2025-11-07
## Updated by Claude Code on 2025-11-10
##
## PURPOSE:
## Disable Swift macro validation for Xcode Cloud builds
## This allows StructuredQueriesMacros from swift-structured-queries to be used
## without requiring manual trust approval in CI environment.
##

set -e  # Exit on error

echo "🔧 Running pre-xcodebuild script..."
echo "   Disabling macro validation for Xcode Cloud build"

# Export build setting to disable package plugin validation
# This is passed to xcodebuild automatically by Xcode Cloud
export DISABLE_PACKAGE_PLUGIN_VALIDATION=YES

echo "✅ Pre-xcodebuild script complete"
