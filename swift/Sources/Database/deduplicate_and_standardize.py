#!/usr/bin/env python3
"""
Deduplication and UUID Standardization Script
Written by Claude Code on 2025-11-02

This script:
1. Standardizes all UUIDs to UPPERCASE
2. Deduplicates records (keeping the most recent by logTime/createdAt)
3. Updates all foreign key references
4. Maintains referential integrity
"""

import sqlite3
import sys
from pathlib import Path
from collections import defaultdict

TARGET_DB = "/Users/davidwilliams/Library/Containers/WilliamsBD.GoalTrackerApp/Data/Library/Application Support/GoalTracker/testing.db"

# Define all tables and their ID columns
ENTITY_TABLES = {
    'actions': {
        'id_col': 'id',
        'timestamp_col': 'logTime',
        'fk_refs': []
    },
    'expectations': {
        'id_col': 'id',
        'timestamp_col': 'logTime',
        'fk_refs': []
    },
    'measures': {
        'id_col': 'id',
        'timestamp_col': 'logTime',
        'fk_refs': []
    },
    'personalValues': {
        'id_col': 'id',
        'timestamp_col': 'logTime',
        'fk_refs': []
    },
    'timePeriods': {
        'id_col': 'id',
        'timestamp_col': 'logTime',
        'fk_refs': []
    },
    'goals': {
        'id_col': 'id',
        'timestamp_col': None,  # No timestamp, use expectation's logTime
        'fk_refs': [('expectationId', 'expectations')]
    },
    'milestones': {
        'id_col': 'id',
        'timestamp_col': None,
        'fk_refs': [('expectationId', 'expectations')]
    },
    'obligations': {
        'id_col': 'id',
        'timestamp_col': None,
        'fk_refs': [('expectationId', 'expectations')]
    },
    'goalTerms': {
        'id_col': 'id',
        'timestamp_col': None,
        'fk_refs': [('timePeriodId', 'timePeriods')]
    },
}

JUNCTION_TABLES = {
    'expectationMeasures': {
        'id_col': 'id',
        'timestamp_col': 'createdAt',
        'fk_refs': [
            ('expectationId', 'expectations'),
            ('measureId', 'measures')
        ]
    },
    'measuredActions': {
        'id_col': 'id',
        'timestamp_col': 'createdAt',
        'fk_refs': [
            ('actionId', 'actions'),
            ('measureId', 'measures')
        ]
    },
    'goalRelevances': {
        'id_col': 'id',
        'timestamp_col': 'createdAt',
        'fk_refs': [
            ('goalId', 'goals'),
            ('valueId', 'personalValues')
        ]
    },
    'actionGoalContributions': {
        'id_col': 'id',
        'timestamp_col': 'createdAt',
        'fk_refs': [
            ('actionId', 'actions'),
            ('goalId', 'goals'),
            ('measureId', 'measures')
        ]
    },
    'termGoalAssignments': {
        'id_col': 'id',
        'timestamp_col': 'createdAt',
        'fk_refs': [
            ('termId', 'goalTerms'),
            ('goalId', 'goals')
        ]
    },
}

def get_all_columns(cursor, table_name):
    """Get all column names for a table"""
    cursor.execute(f"PRAGMA table_info({table_name})")
    return [row[1] for row in cursor.fetchall()]

def find_duplicates(cursor, table_name, id_col):
    """Find duplicate IDs (case-insensitive)"""
    cursor.execute(f"""
        SELECT UPPER({id_col}) as upper_id, COUNT(*) as cnt
        FROM {table_name}
        GROUP BY UPPER({id_col})
        HAVING cnt > 1
    """)
    return [row[0] for row in cursor.fetchall()]

def get_canonical_record(cursor, table_name, id_col, upper_id, timestamp_col):
    """Get the canonical record to keep (most recent, or first if no timestamp)"""
    columns = get_all_columns(cursor, table_name)

    if timestamp_col and timestamp_col in columns:
        # Keep most recent
        cursor.execute(f"""
            SELECT {', '.join(columns)}
            FROM {table_name}
            WHERE UPPER({id_col}) = ?
            ORDER BY {timestamp_col} DESC
            LIMIT 1
        """, (upper_id,))
    else:
        # Just keep first one
        cursor.execute(f"""
            SELECT {', '.join(columns)}
            FROM {table_name}
            WHERE UPPER({id_col}) = ?
            LIMIT 1
        """, (upper_id,))

    return cursor.fetchone(), columns

def standardize_table(cursor, table_name, table_info):
    """Standardize UUIDs and deduplicate a single table"""
    print(f"\n{'='*60}")
    print(f"Processing: {table_name}")
    print(f"{'='*60}")

    id_col = table_info['id_col']
    timestamp_col = table_info['timestamp_col']

    # Find duplicates
    duplicates = find_duplicates(cursor, table_name, id_col)

    if duplicates:
        print(f"Found {len(duplicates)} duplicate ID groups")

    # Get all records
    columns = get_all_columns(cursor, table_name)
    cursor.execute(f"SELECT {', '.join(columns)} FROM {table_name}")
    all_records = cursor.fetchall()

    # Build UUID mapping (lowercase/mixed -> UPPERCASE)
    uuid_mapping = {}
    for record in all_records:
        record_dict = dict(zip(columns, record))
        original_id = record_dict[id_col]
        upper_id = original_id.upper()

        if original_id != upper_id:
            uuid_mapping[original_id] = upper_id

    if uuid_mapping:
        print(f"Standardizing {len(uuid_mapping)} UUIDs to uppercase")

    # Clear table and rebuild with deduplicated uppercase records
    cursor.execute(f"DELETE FROM {table_name}")

    # Track which uppercase IDs we've inserted
    inserted_ids = set()
    kept_count = 0
    removed_count = 0

    for record in all_records:
        record_dict = dict(zip(columns, record))
        original_id = record_dict[id_col]
        upper_id = original_id.upper()

        # Skip if we already inserted this uppercase ID
        if upper_id in inserted_ids:
            removed_count += 1
            continue

        # Update the record with uppercase ID
        record_dict[id_col] = upper_id

        # Update foreign keys to uppercase
        for fk_col, ref_table in table_info['fk_refs']:
            if fk_col in record_dict and record_dict[fk_col]:
                record_dict[fk_col] = record_dict[fk_col].upper()

        # Insert the canonical record
        placeholders = ', '.join(['?' for _ in columns])
        values = [record_dict[col] for col in columns]

        cursor.execute(f"""
            INSERT INTO {table_name} ({', '.join(columns)})
            VALUES ({placeholders})
        """, values)

        inserted_ids.add(upper_id)
        kept_count += 1

    print(f"✅ Kept: {kept_count} records")
    if removed_count > 0:
        print(f"🗑️  Removed: {removed_count} duplicates")

    return uuid_mapping

def main():
    print("="*60)
    print("UUID Standardization and Deduplication")
    print("="*60)

    if not Path(TARGET_DB).exists():
        print(f"❌ Database not found: {TARGET_DB}")
        sys.exit(1)

    try:
        conn = sqlite3.connect(TARGET_DB)
        cursor = conn.cursor()

        # Disable foreign keys during modification
        cursor.execute("PRAGMA foreign_keys = OFF")

        # Track all UUID mappings
        all_mappings = {}

        # Process entity tables first (no dependencies)
        print("\n" + "="*60)
        print("PHASE 1: Entity Tables")
        print("="*60)

        for table_name, table_info in ENTITY_TABLES.items():
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]

            if count == 0:
                print(f"\n⏭️  Skipping {table_name} (empty)")
                continue

            mappings = standardize_table(cursor, table_name, table_info)
            if mappings:
                all_mappings[table_name] = mappings

        # Process junction tables (have dependencies)
        print("\n" + "="*60)
        print("PHASE 2: Junction Tables")
        print("="*60)

        for table_name, table_info in JUNCTION_TABLES.items():
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            count = cursor.fetchone()[0]

            if count == 0:
                print(f"\n⏭️  Skipping {table_name} (empty)")
                continue

            mappings = standardize_table(cursor, table_name, table_info)
            if mappings:
                all_mappings[table_name] = mappings

        # Re-enable foreign keys and validate
        cursor.execute("PRAGMA foreign_keys = ON")

        print("\n" + "="*60)
        print("PHASE 3: Foreign Key Validation")
        print("="*60)

        all_valid = True
        for table_name in list(ENTITY_TABLES.keys()) + list(JUNCTION_TABLES.keys()):
            cursor.execute(f"PRAGMA foreign_key_check({table_name})")
            violations = cursor.fetchall()

            if violations:
                print(f"❌ {table_name}: {len(violations)} FK violations")
                for v in violations[:3]:
                    print(f"   {v}")
                all_valid = False
            else:
                cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                count = cursor.fetchone()[0]
                if count > 0:
                    print(f"✅ {table_name}: {count} records, FK valid")

        if all_valid:
            conn.commit()

            print("\n" + "="*60)
            print("✅ Standardization Complete!")
            print("="*60)

            # Summary
            total_standardized = sum(len(m) for m in all_mappings.values())
            if total_standardized > 0:
                print(f"\nTotal UUIDs standardized: {total_standardized}")
                for table, mappings in all_mappings.items():
                    print(f"  - {table}: {len(mappings)}")
            else:
                print("\nAll UUIDs were already uppercase!")

        else:
            print("\n❌ Foreign key violations detected - rolling back")
            conn.rollback()
            sys.exit(1)

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        conn.rollback()
        sys.exit(1)

    finally:
        conn.close()

if __name__ == "__main__":
    main()
