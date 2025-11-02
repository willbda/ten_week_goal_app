#!/usr/bin/env python3
"""
Migration script to populate testing.db from new_production.db
Written by Claude Code on 2025-11-02

Handles schema differences:
- Table name case differences (personalvalues -> personalValues)
- Missing UNIQUE constraints in target
- Validates foreign key relationships
"""

import sqlite3
import sys
from pathlib import Path

# Database paths
SOURCE_DB = "/Users/davidwilliams/Coding/01_ACTIVE_PROJECTS/ten_week_goal_app/swift/Sources/Database/new_production.db"
TARGET_DB = "/Users/davidwilliams/Library/Containers/WilliamsBD.GoalTrackerApp/Data/Library/Application Support/GoalTracker/testing.db"

# Table name mappings (source -> target)
TABLE_MAPPINGS = {
    'actions': 'actions',
    'expectations': 'expectations',
    'measures': 'measures',
    'personalvalues': 'personalValues',
    'timeperiods': 'timePeriods',
    'goals': 'goals',
    'milestones': 'milestones',
    'obligations': 'obligations',
    'goalterms': 'goalTerms',
    'expectationmeasures': 'expectationMeasures',
    'measuredactions': 'measuredActions',
    'goalrelevances': 'goalRelevances',
    'actiongoalcontributions': 'actionGoalContributions',
    'termgoalassignments': 'termGoalAssignments',
}

def get_column_names(cursor, table_name):
    """Get column names for a table"""
    cursor.execute(f"PRAGMA table_info({table_name})")
    return [row[1] for row in cursor.fetchall()]

def migrate_table(source_cursor, target_cursor, source_table, target_table):
    """Migrate data from source table to target table"""
    print(f"\n{'='*60}")
    print(f"Migrating: {source_table} -> {target_table}")
    print(f"{'='*60}")

    # Get column names from both databases
    source_cols = get_column_names(source_cursor, source_table)
    target_cols = get_column_names(target_cursor, target_table)

    # Find common columns
    common_cols = [col for col in source_cols if col in target_cols]

    if not common_cols:
        print(f"❌ No common columns found!")
        return 0

    print(f"Columns to migrate: {', '.join(common_cols)}")

    # Fetch data from source
    source_cursor.execute(f"SELECT {', '.join(common_cols)} FROM {source_table}")
    rows = source_cursor.fetchall()

    if not rows:
        print(f"⚠️  No data to migrate")
        return 0

    print(f"Found {len(rows)} rows")

    # Check if target table already has data
    target_cursor.execute(f"SELECT COUNT(*) FROM {target_table}")
    existing_count = target_cursor.fetchone()[0]

    if existing_count > 0:
        print(f"⚠️  Target table already has {existing_count} rows. Clearing...")
        target_cursor.execute(f"DELETE FROM {target_table}")

    # Insert data into target
    placeholders = ', '.join(['?' for _ in common_cols])
    insert_sql = f"INSERT INTO {target_table} ({', '.join(common_cols)}) VALUES ({placeholders})"

    migrated = 0
    failed = 0

    for row in rows:
        try:
            target_cursor.execute(insert_sql, row)
            migrated += 1
        except sqlite3.IntegrityError as e:
            failed += 1
            # Only print first few errors to avoid clutter
            if failed <= 3:
                print(f"⚠️  Failed to insert row: {e}")

    print(f"✅ Migrated: {migrated} rows")
    if failed > 0:
        print(f"❌ Failed: {failed} rows (likely duplicates)")

    return migrated

def verify_foreign_keys(cursor, table_name):
    """Verify foreign key integrity for a table"""
    cursor.execute(f"PRAGMA foreign_key_check({table_name})")
    violations = cursor.fetchall()
    if violations:
        print(f"❌ Foreign key violations in {table_name}:")
        for v in violations[:5]:  # Show first 5
            print(f"   {v}")
        return False
    return True

def main():
    print("="*60)
    print("Database Migration: new_production.db -> testing.db")
    print("="*60)

    # Verify source database exists
    if not Path(SOURCE_DB).exists():
        print(f"❌ Source database not found: {SOURCE_DB}")
        sys.exit(1)

    # Verify target database exists
    if not Path(TARGET_DB).exists():
        print(f"❌ Target database not found: {TARGET_DB}")
        sys.exit(1)

    try:
        # Connect to databases
        source_conn = sqlite3.connect(SOURCE_DB)
        target_conn = sqlite3.connect(TARGET_DB)

        source_cursor = source_conn.cursor()
        target_cursor = target_conn.cursor()

        # Disable foreign keys during migration
        target_cursor.execute("PRAGMA foreign_keys = OFF")

        # Migration order (respecting foreign key dependencies)
        migration_order = [
            # Base entities first (no dependencies)
            ('actions', 'actions'),
            ('expectations', 'expectations'),
            ('measures', 'measures'),
            ('personalvalues', 'personalValues'),
            ('timeperiods', 'timePeriods'),

            # Entities that depend on base entities
            ('goals', 'goals'),
            ('milestones', 'milestones'),
            ('obligations', 'obligations'),
            ('goalterms', 'goalTerms'),

            # Junction tables (depend on multiple entities)
            ('expectationmeasures', 'expectationMeasures'),
            ('measuredactions', 'measuredActions'),
            ('goalrelevances', 'goalRelevances'),
            ('actiongoalcontributions', 'actionGoalContributions'),
            ('termgoalassignments', 'termGoalAssignments'),
        ]

        total_migrated = 0

        # Migrate each table
        for source_table, target_table in migration_order:
            count = migrate_table(source_cursor, target_cursor, source_table, target_table)
            total_migrated += count

        # Re-enable foreign keys
        target_cursor.execute("PRAGMA foreign_keys = ON")

        # Verify foreign key integrity
        print(f"\n{'='*60}")
        print("Verifying Foreign Key Integrity")
        print(f"{'='*60}")

        all_valid = True
        for _, target_table in migration_order:
            if not verify_foreign_keys(target_cursor, target_table):
                all_valid = False

        if all_valid:
            print("✅ All foreign key constraints valid")

            # Commit changes
            target_conn.commit()
            print(f"\n{'='*60}")
            print(f"✅ Migration Complete!")
            print(f"Total rows migrated: {total_migrated}")
            print(f"{'='*60}")
        else:
            print("\n❌ Foreign key violations detected - rolling back")
            target_conn.rollback()
            sys.exit(1)

    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        source_conn.close()
        target_conn.close()

if __name__ == "__main__":
    main()
