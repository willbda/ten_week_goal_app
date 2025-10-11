"""
Testing configuration.

Provides test-specific database paths and configuration.
Keeps test data separate from production data.

Written by Claude Code on 2025-10-11
"""

from pathlib import Path

# Test database paths - separate from production
PROJECT_ROOT = Path(__file__).parent.parent
TEST_DATA_DIR = PROJECT_ROOT / 'test_data'
TEST_DB_PATH = TEST_DATA_DIR / 'testing.db'

# Use same schemas as production
SCHEMA_PATH = PROJECT_ROOT / 'politica' / 'schemas'


def clean_test_database():
    """
    Remove test database to start fresh.

    Call this before test runs to ensure clean state.
    """
    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink()
        print(f"✓ Cleaned test database: {TEST_DB_PATH}")


def ensure_test_data_dir():
    """Ensure test data directory exists."""
    TEST_DATA_DIR.mkdir(parents=True, exist_ok=True)
