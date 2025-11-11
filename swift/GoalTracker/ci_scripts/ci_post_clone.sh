##!/bin/sh
#
##
## ci_post_clone.sh
## Xcode Cloud post-clone script
## Written by Claude Code on 2025-11-07
##
## PURPOSE:
## Skip Swift macro validation for Xcode Cloud builds
## This allows StructuredQueriesMacros from swift-structured-queries to be used
## without requiring manual trust approval in CI environment.
##
## SECURITY NOTE:
## This skips ALL macro validation. Ensure your Package.resolved pins
## specific versions of dependencies to prevent malicious code injection.
##
#
#set -e  # Exit on error
#
#echo "🔧 Running post-clone script..."
#echo "   Configuring Xcode to skip macro validation"
#
## Skip macro fingerprint validation (required for Xcode Cloud)
#defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
#
#echo "✅ Post-clone script complete - macro validation disabled"
