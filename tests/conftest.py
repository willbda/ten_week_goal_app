"""
Pytest configuration and shared fixtures.

Provides test database fixtures and setup/teardown logic.
All tests have access to these fixtures automatically.

Written by Claude Code on 2025-10-11
"""

import pytest
from pathlib import Path
from politica.database import Database
from config.testing import TEST_DB_PATH, SCHEMA_PATH, clean_test_database, ensure_test_data_dir


@pytest.fixture(scope='session', autouse=True)
def setup_test_environment():
    """
    Setup run once for entire test session.

    Creates test data directory and cleans old test database.
    Runs automatically (autouse=True) before any tests.
    """
    print("\n" + "="*60)
    print("SETTING UP TEST ENVIRONMENT")
    print("="*60)

    ensure_test_data_dir()
    clean_test_database()

    yield  # Tests run here

    print("\n" + "="*60)
    print("TEST SESSION COMPLETE")
    print(f"Test database location: {TEST_DB_PATH}")
    print("="*60)


@pytest.fixture
def test_db():
    """
    Provide clean test database for each test.

    Creates fresh database before each test.
    Database persists at test_data/testing.db for inspection.

    Returns:
        tuple: (Database instance, Path to database file)
    """
    # Clean before each test for isolation
    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink()

    # Create fresh database with production schemas
    db = Database(db_path=TEST_DB_PATH, schema_dir=SCHEMA_PATH)

    yield db, TEST_DB_PATH

    # Database persists after test for inspection
    # Run `python -m pytest --verbose` to see test database location


@pytest.fixture
def persistent_test_db():
    """
    Provide persistent test database across multiple tests.

    Use this when you want to accumulate test data across tests
    in the same test run. Database is NOT cleaned between tests.

    Returns:
        tuple: (Database instance, Path to database file)

    Example:
        def test_one(persistent_test_db):
            db, _ = persistent_test_db
            # Add some data

        def test_two(persistent_test_db):
            db, _ = persistent_test_db
            # Data from test_one still exists
    """
    # Create if doesn't exist, reuse if it does
    db = Database(db_path=TEST_DB_PATH, schema_dir=SCHEMA_PATH)

    yield db, TEST_DB_PATH
