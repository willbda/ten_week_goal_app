#!/usr/bin/env python3
"""
UUID Lowercase Normalization Script
Written by Claude Code on 2025-11-02

Normalizes all UUIDs to lowercase (Swift/GRDB default format).
Run this once to fix the uppercase UUIDs introduced by deduplication script.

Usage:
    python3 lowercase_uuids.py

This will lowercase all UUID columns in:
    ~/Library/Containers/*/Data/Library/Application Support/GoalTracker/*.db
"""

import sqlite3
import glob
import os
from pathlib import Path

# All tables with their UUID columns
TABLES_WITH_UUIDS = {
    # Abstractions
    'actions': ['id'],
    'expectations': ['id'],
    'measures': ['id'],
    'personalValues': ['id'],
    'timePeriods': ['id'],

    # Basics
    'goals': ['id', 'expectationId'],
    'milestones': ['id', 'expectationId'],
    'obligations': ['id', 'expectationId'],
    'goalTerms': ['id', 'timePeriodId'],

    # Composits (junction tables)
    'expectationMeasures': ['id', 'expectationId', 'measureId'],
    'measuredActions': ['id', 'actionId', 'measureId'],
    'goalRelevances': ['id', 'goalId', 'valueId'],
    'actionGoalContributions': ['id', 'actionId', 'goalId'],
    'termGoalAssignments': ['id', 'termId', 'goalId'],
}

def find_databases():
    """Find all GoalTracker databases."""
    pattern = os.path.expanduser("~/Library/Containers/*/Data/Library/Application Support/GoalTracker/*.db")
    dbs = glob.glob(pattern)
    return dbs

def lowercase_uuids_in_table(cursor, table_name, uuid_columns):
    """Lowercase all UUID columns in a table."""
    print(f"  Processing {table_name}...")

    # Check if table exists
    cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}'")
    if not cursor.fetchone():
        print(f"    ⚠️  Table {table_name} doesn't exist, skipping")
        return

    # Lowercase each UUID column
    for col in uuid_columns:
        try:
            # Check if column exists
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = [row[1] for row in cursor.fetchall()]

            if col not in columns:
                print(f"    ⚠️  Column {col} doesn't exist in {table_name}, skipping")
                continue

            # Lowercase the UUIDs
            cursor.execute(f"""
                UPDATE {table_name}
                SET {col} = LOWER({col})
                WHERE {col} IS NOT NULL
            """)

            rows_updated = cursor.rowcount
            if rows_updated > 0:
                print(f"    ✅ Lowercased {rows_updated} rows in {table_name}.{col}")

        except sqlite3.Error as e:
            print(f"    ❌ Error updating {table_name}.{col}: {e}")

def lowercase_all_uuids(db_path):
    """Lowercase all UUIDs in a database."""
    print(f"\n📂 Processing database: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    try:
        # Process each table
        for table_name, uuid_columns in TABLES_WITH_UUIDS.items():
            lowercase_uuids_in_table(cursor, table_name, uuid_columns)

        # Commit all changes
        conn.commit()
        print(f"✅ Successfully normalized UUIDs in {db_path}")

    except Exception as e:
        conn.rollback()
        print(f"❌ Error processing {db_path}: {e}")

    finally:
        conn.close()

def main():
    print("UUID Lowercase Normalization")
    print("=" * 60)
    print("This script will lowercase all UUIDs to match Swift/GRDB defaults.")
    print()

    # Find databases
    databases = find_databases()

    if not databases:
        print("❌ No databases found!")
        print("   Looking in: ~/Library/Containers/*/Data/Library/Application Support/GoalTracker/")
        return

    print(f"Found {len(databases)} database(s):")
    for db in databases:
        print(f"  - {db}")

    # Confirm
    response = input("\nProceed with lowercasing UUIDs? (yes/no): ")
    if response.lower() not in ['yes', 'y']:
        print("Aborted.")
        return

    # Process each database
    for db_path in databases:
        lowercase_all_uuids(db_path)

    print("\n" + "=" * 60)
    print("✅ UUID normalization complete!")
    print("\nNext steps:")
    print("  1. Restart the app")
    print("  2. CloudKit should now see records correctly")
    print("  3. No more duplicate entries!")

if __name__ == "__main__":
    main()
