# Testing Guide

## Test Database Setup

Tests use a **persistent testing database** separate from production:

```
test_data/testing.db  ← Test database (git-ignored)
politica/data_storage/application_data.db  ← Production database
```

## How It Works

### Automatic Setup (conftest.py)

`tests/conftest.py` provides fixtures automatically available to all tests:

1. **`test_db` fixture** - Clean database for each test
   - Database is **wiped clean** before each test
   - Ensures test isolation
   - Database persists after test for inspection

2. **`persistent_test_db` fixture** - Shared database across tests
   - Database is **NOT** cleaned between tests
   - Use when tests need to build on previous test data

### Running Tests

```bash
# Run all tests
python -m pytest tests/ -v

# Run specific test file
python -m pytest tests/test_storage.py -v

# Run specific test
python -m pytest tests/test_storage.py::test_action_save -v
```

### Inspecting Test Data

After tests run, inspect the test database:

```bash
# View test database location
ls -lh test_data/

# Query test database with sqlite3
sqlite3 test_data/testing.db
sqlite> .tables
sqlite> SELECT * FROM actions;
sqlite> .exit
```

## Test Structure Example

```python
def test_action_save(test_db):
    """Test using clean database"""
    db, db_path = test_db

    # db is a fresh Database instance
    # db_path points to test_data/testing.db

    service = ActionStorageService(database=db)
    service.store_many_instances(entities=actions)

    # Verify
    stored = service.get_all()
    assert len(stored) == 3
```

## Key Benefits

### 1. **Production Safety**
- Tests NEVER touch production database
- Complete isolation via dependency injection

### 2. **Debuggability**
- Test database persists after test failure
- Can inspect actual data that caused failure
- Located at: `test_data/testing.db`

### 3. **Speed**
- Same schema as production
- No need to rebuild schema each time
- Fast test execution

### 4. **Clean Tests**
- Each test gets fresh database
- No test pollution or order dependencies

## Cleaning Test Data

```bash
# Remove test database manually
rm test_data/testing.db

# Or use the utility function
python -c "from config.testing import clean_test_database; clean_test_database()"
```

## Configuration Files

- `tests/conftest.py` - Pytest fixtures and setup
- `config/testing.py` - Test database paths and utilities
- `.gitignore` - Excludes `test_data/` from version control
