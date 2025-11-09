"""
UUID Migration Utilities

Provides helper functions to backfill UUID values for existing records in the database.
This supports the transition from INTEGER-only IDs to the dual ID system (INTEGER + UUID).

Written by Claude Code on 2025-10-21
"""

from uuid import uuid4
from typing import List, Dict, Optional
from politica.database import Database
from config.logging_setup import get_logger

logger = get_logger(__name__)


def backfill_uuids_for_table(table: str, db: Optional[Database] = None) -> Dict[str, int]:
    """
    Generate and populate UUID values for all records in a table that don't have one.

    Args:
        table: Table name (e.g., 'actions', 'goals', 'personal_values', 'terms')
        db: Database instance (creates default if None)

    Returns:
        Dict with migration statistics:
        {
            'table': str,
            'total_records': int,
            'records_missing_uuid': int,
            'records_updated': int,
            'errors': int
        }

    Example:
        >>> stats = backfill_uuids_for_table('actions')
        >>> print(f"Updated {stats['records_updated']} actions with UUIDs")
    """
    if db is None:
        db = Database()

    logger.info(f"Starting UUID backfill for table: {table}")

    # Query all records
    all_records = db.query(table)
    total_count = len(all_records)

    # Find records missing UUIDs
    missing_uuid = [r for r in all_records if not r.get('uuid_id')]
    missing_count = len(missing_uuid)

    logger.info(f"Found {total_count} total records, {missing_count} missing UUIDs")

    if missing_count == 0:
        logger.info("No records need UUID backfill")
        return {
            'table': table,
            'total_records': total_count,
            'records_missing_uuid': 0,
            'records_updated': 0,
            'errors': 0
        }

    # Generate and update UUIDs
    updated_count = 0
    error_count = 0

    for record in missing_uuid:
        record_id = record.get('id')
        if not record_id:
            logger.warning(f"Record without id found in {table}, skipping")
            error_count += 1
            continue

        # Generate new UUID
        new_uuid = str(uuid4())

        try:
            # Update record with UUID
            db.update(
                table=table,
                record_id=record_id,
                updates={'uuid_id': new_uuid},
                archive_old=False  # Don't archive during migration
            )
            updated_count += 1

            if updated_count % 100 == 0:
                logger.info(f"Progress: {updated_count}/{missing_count} records updated")

        except Exception as e:
            logger.error(f"Failed to update record {record_id} in {table}: {e}")
            error_count += 1

    logger.info(f"UUID backfill complete for {table}: {updated_count} updated, {error_count} errors")

    return {
        'table': table,
        'total_records': total_count,
        'records_missing_uuid': missing_count,
        'records_updated': updated_count,
        'errors': error_count
    }


def backfill_all_tables(tables: Optional[List[str]] = None, db: Optional[Database] = None) -> List[Dict]:
    """
    Backfill UUIDs for multiple tables.

    Args:
        tables: List of table names (defaults to standard entity tables)
        db: Database instance (creates default if None)

    Returns:
        List of statistics dicts (one per table)

    Example:
        >>> results = backfill_all_tables()
        >>> for stats in results:
        ...     print(f"{stats['table']}: {stats['records_updated']} updated")
    """
    if tables is None:
        tables = ['actions', 'goals', 'personal_values', 'terms']

    if db is None:
        db = Database()

    logger.info(f"Starting UUID backfill for {len(tables)} tables")

    results = []
    for table in tables:
        stats = backfill_uuids_for_table(table, db=db)
        results.append(stats)

    # Summary
    total_updated = sum(r['records_updated'] for r in results)
    total_errors = sum(r['errors'] for r in results)

    logger.info(f"Migration complete: {total_updated} total records updated, {total_errors} errors")

    return results


def verify_uuid_coverage(table: str, db: Optional[Database] = None) -> Dict[str, int]:
    """
    Check UUID coverage for a table without making changes.

    Args:
        table: Table name
        db: Database instance (creates default if None)

    Returns:
        Dict with coverage statistics:
        {
            'table': str,
            'total_records': int,
            'with_uuid': int,
            'missing_uuid': int,
            'coverage_percent': float
        }

    Example:
        >>> stats = verify_uuid_coverage('actions')
        >>> print(f"UUID coverage: {stats['coverage_percent']:.1f}%")
    """
    if db is None:
        db = Database()

    all_records = db.query(table)
    total = len(all_records)

    with_uuid = sum(1 for r in all_records if r.get('uuid_id'))
    missing = total - with_uuid

    coverage = (with_uuid / total * 100) if total > 0 else 0.0

    return {
        'table': table,
        'total_records': total,
        'with_uuid': with_uuid,
        'missing_uuid': missing,
        'coverage_percent': coverage
    }


if __name__ == '__main__':
    """
    Run migration from command line:

    python politica/uuid_migration.py
    """
    import sys

    print("UUID Migration Utility")
    print("=" * 60)
    print()

    # Check coverage first
    print("Checking current UUID coverage...")
    tables = ['actions', 'goals', 'personal_values', 'terms']

    for table in tables:
        stats = verify_uuid_coverage(table)
        print(f"  {table:20} {stats['with_uuid']:4}/{stats['total_records']:4} "
              f"({stats['coverage_percent']:5.1f}% coverage)")

    print()

    # Ask for confirmation
    response = input("Run UUID backfill migration? (yes/no): ")
    if response.lower() not in ('yes', 'y'):
        print("Migration cancelled")
        sys.exit(0)

    print()
    print("Running migration...")
    print()

    # Run migration
    results = backfill_all_tables(tables)

    # Print results
    print()
    print("Migration Results:")
    print("-" * 60)
    for stats in results:
        print(f"{stats['table']:20} "
              f"Updated: {stats['records_updated']:4}  "
              f"Errors: {stats['errors']:4}")

    print()
    print("Migration complete!")
