"""
SQLite database operations with no knowledge of domain entities.

This module provides a clean interface to SQLite, working exclusively with:
- Table names (strings)
- Column names (strings)
- Primitive values (dicts with basic types)

All methods accept/return dicts, never domain objects like Action or Goal.

"""

import sqlite3
import json
from pathlib import Path
from typing import List, Optional
from contextlib import contextmanager
from config import DB_PATH, SCHEMA_PATH
from config.logging_setup import get_logger

# Module logger
logger = get_logger(__name__)


def _archive_records(db_connection, table: str, records: List[dict], reason: str, notes: str = '') -> None:
    """
    Archive records to archive table.

    PRIVATE MODULE FUNCTION - Not part of Database class API.
    Use Database.archive_and_delete() instead.

    Args:
        db_connection: Active database connection (from context manager)
        table: Source table name
        records: List of record dicts to archive
        reason: Why archiving ('delete', 'update', 'manual')
        notes: Optional additional context
    """
    if not records:
        logger.debug("No records to archive")
        return

    logger.info(f"Archiving {len(records)} records from {table} (reason: {reason})")

    cursor = db_connection.cursor()

    for record in records:
        record_json = json.dumps(record, default=str)

        cursor.execute("""
            INSERT INTO archive (source_table, source_id, record_data, reason, notes)
            VALUES (?, ?, ?, ?, ?)
        """, (
            table,
            record.get('id'),
            record_json,
            reason,
            notes
        ))

    logger.info(f"✓ Archived {len(records)} records from {table}")


def _delete_records_unsafe(db_connection, table: str, filters: dict) -> int:
    """
    Delete records without archiving.

    PRIVATE MODULE FUNCTION - Not part of Database class API.

    This exists only as a primitive for safe composition within this module.

    Args:
        db_connection: Active database connection (from context manager)
        table: Name of the database table
        filters: Dict of column:value pairs for WHERE clause

    Returns:
        Number of rows deleted

    Raises:
        ValueError: If filters is empty (prevents deleting all records)
    """
    if not filters:
        logger.error("Attempted to delete without filters - would delete ALL records!")
        raise ValueError("Must provide filters to prevent deleting all records")

    # Build WHERE clause
    conditions = [f"{col} = ?" for col in filters.keys()]
    where_sql = " WHERE " + " AND ".join(conditions)
    values = list(filters.values())

    sql = f"DELETE FROM {table}{where_sql}"

    logger.warning(f"⚠️  UNSAFE DELETE from {table} with filters: {filters}")

    cursor = db_connection.cursor()
    cursor.execute(sql, values)
    rows_deleted = cursor.rowcount

    logger.warning(f"⚠️  DELETED {rows_deleted} records from {table}")
    return rows_deleted



class Database:
    """
    Generic SQLite database interface.

    Handles all database operations without knowledge of domain entities.
    Initialized once per application with database path and schemas.
    """

    def __init__(self, db_path: Path = DB_PATH, schema_dir: Path = SCHEMA_PATH):
        """
        Initialize database connection manager.

        Ensures database exists with proper schema. Creates if missing.
        Raises error if database cannot be created or schemas are invalid.

        Args:
            db_path: Path to SQLite database file
            schema_dir: Directory containing .sql schema files

        Raises:
            FileNotFoundError: If schema files not found
            sqlite3.Error: If database initialization fails
        """
        self.db_path = db_path
        self.schema_dir = schema_dir

        # Ensure database exists with schema
        self._ensure_initialized()

    def _ensure_initialized(self):
        """
        Check if database exists, initialize if not.

        Creates storage directory and executes all schema files.
        Logs each step for debugging.
        """
        if self.db_path.exists():
            logger.info(f"Database found at {self.db_path}")
            return

        logger.warning(f"Database not found at {self.db_path}, initializing...")

        # Create storage directory
        storage_path = self.db_path.parent
        storage_path.mkdir(parents=True, exist_ok=True)

        # Find schema files
        schema_files = sorted(self.schema_dir.glob('*.sql'))
        if not schema_files:
            logger.error(f"No schema files found in {self.schema_dir}")
            raise FileNotFoundError(f"No .sql files in {self.schema_dir}")

        logger.info(f"Found {len(schema_files)} schema files to execute")

        # Execute schemas
        conn = sqlite3.connect(self.db_path)
        try:
            for schema_file in schema_files:
                logger.info(f"Executing schema: {schema_file.name}")
                with open(schema_file, 'r') as f:
                    schema = f.read()
                    conn.executescript(schema)

            conn.commit()
            logger.info("✓ Database initialized successfully with all schemas")
        except sqlite3.Error as e:
            logger.error(f"Failed to initialize database: {e}")
            raise
        except FileNotFoundError as e:
            logger.error(f"Schema file not found: {e}")
            raise
        finally:
            conn.close()

    @contextmanager
    def _get_connection(self):
        """
        Context manager for database connections.

        Handles connection lifecycle:
        - Opens connection with Row factory (returns dict-like rows)
        - Commits on success
        - Rolls back on exception
        - Always closes connection

        Usage:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(sql, values)
        """
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # Return dict-like rows

        try:
            yield conn
            conn.commit()
            logger.debug("Database transaction committed")
        except Exception as e:
            conn.rollback()
            logger.error(f"Database transaction rolled back: {e}")
            raise
        finally:
            conn.close()
            logger.debug("Database connection closed")

    def _build_where_clause(self, filters: dict) -> tuple[str, list]:
        """
        Build SQL WHERE clause from filters dictionary.

        Args:
            filters: Dict of column:value pairs
                     Example: {'unit': 'km_run', 'id': 5}

        Returns:
            Tuple of (sql_string, values_list)
            Example: (" WHERE unit = ? AND id = ?", ['km_run', 5])
        """
        if not filters:
            return "", []

        conditions = [f"{col} = ?" for col in filters.keys()]
        where_sql = " WHERE " + " AND ".join(conditions)
        values = list(filters.values())

        return where_sql, values

    def _build_set_clause(self, updates: dict) -> tuple[str, list]:
        """
        Build SQL SET clause from updates dictionary.

        Args:
            updates: Dict of column:value pairs
                     Example: {'target_date': '2025-12-25', 'measurement_target': 150.0}

        Returns:
            Tuple of (sql_string, values_list)
            Example: ("target_date = ?, measurement_target = ?", ['2025-12-25', 150.0])
        """
        if not updates:
            return "", []

        set_clauses = [f"{col} = ?" for col in updates.keys()]
        set_sql = ", ".join(set_clauses)
        values = list(updates.values())

        return set_sql, values


    def query(self, table: str, filters: Optional[dict] = None, order_by: Optional[str] = None) -> List[dict]:
        """
        Fetch records from a database table.

        Args:
            table: Name of the database table
            filters: Optional dict of column:value pairs for WHERE clause
                     Example: {'unit': 'km_run', 'start_date': '2025-10-10'}
            order_by: Optional column name to order results by
                      Example: 'created_at DESC'

        Returns:
            List of dicts, each representing a row from the table
            Empty list if no records found

        Example:
            # Get all actions
            actions = db.query('actions')

            # Get goals with specific unit
            running_goals = db.query('goals', filters={'unit': 'km_run'})

            # Get recent actions
            recent = db.query('actions', order_by='log_time DESC')
        """
        # Build SQL query
        sql = f"SELECT * FROM {table}"
        values = []

        # Add WHERE clause if filters provided
        if filters:
            where_sql, values = self._build_where_clause(filters)
            sql += where_sql

        # Add ORDER BY if specified
        if order_by:
            sql += f" ORDER BY {order_by}"

        logger.info(f"Querying {len(filters) if filters else 'all'} records from {table}")
        logger.debug(f"SQL: {sql}")
        logger.debug(f"Values: {values}")

        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(sql, values)
            rows = cursor.fetchall()

            # Convert Row objects to regular dicts
            results = [dict(row) for row in rows]

            logger.debug(f"Query returned {len(results)} rows")
            return results

    def insert(self, table: str, records: List[dict]):
        """
        Insert records into a database table.

        Infers column names from first record's keys.
        Handles missing keys gracefully (inserts NULL).

        Args:
            table: Name of the database table
            records: List of dictionaries where keys match table columns

        Returns:
            List[int]: List of inserted record IDs (one per record)
                      For single insert, returns list with one ID

        Example:
            # Insert single goal
            ids = db.insert('goals', [{'name': 'Run 100km', 'measurement_target': 100.0}])
            # ids = [123]

            # Insert multiple actions
            ids = db.insert('actions', [
                {'value': 5.2, 'unit': 'km_run', 'log_time': '2025-10-10 08:00'},
                {'value': 3.1, 'unit': 'km_run', 'log_time': '2025-10-10 18:00'}
            ])
            # ids = [456, 457]
        """
        if not records:
            logger.warning("Attempted to insert empty list of records")
            raise ValueError("Cannot insert empty list of records")

        # Get actual table columns from database schema (not from data!)
        # This ensures we use the schema as the source of truth
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(f"PRAGMA table_info({table})")
            table_info = cursor.fetchall()

            # Extract column names, excluding id (autoincrement)
            # table_info format: (cid, name, type, notnull, dflt_value, pk)
            schema_columns = [col[1] for col in table_info if col[1] != 'id']

            if not schema_columns:
                raise ValueError(f"No columns found in {table} schema (excluding id)")

            # Use schema columns for INSERT statement
            placeholders = ', '.join(['?' for _ in schema_columns])
            columns_str = ', '.join(schema_columns)

            sql = f"INSERT INTO {table} ({columns_str}) VALUES ({placeholders})"
            logger.info(f"Inserting {len(records)} records into {table}")
            logger.debug(f"Using schema columns: {schema_columns}")
            logger.debug(f"SQL: {sql}")

            inserted_ids = []
            for record in records:
                # Use .get() to handle missing keys gracefully (defaults to None)
                # This ensures all schema columns get a value (None if not in record)
                values = [record.get(col) for col in schema_columns]
                cursor.execute(sql, values)
                inserted_ids.append(cursor.lastrowid)

        logger.info(f"✓ Inserted {len(records)} records into {table}. IDs: {inserted_ids[0]}-{inserted_ids[-1]}")
        return inserted_ids


    def update(self, table: str, record_id: int, updates: dict,
               archive_old: bool = True, notes: str = '') -> dict:
        """
        Update a record by ID, optionally archiving the old version.

        Args:
            table: Table name
            record_id: The ID of the record to update
            updates: Dict of column:value pairs to update
                     Example: {'description': 'Updated text', 'measurement_target': 150.0}
            archive_old: If True, archive the old version before updating (default: True)
            notes: Optional notes for the archive entry

        Returns:
            {
                'id': int,              # The updated record ID
                'archived': bool,       # Whether old version was archived
                'updated': bool         # Whether update succeeded
            }

        Raises:
            ValueError: If updates dict is empty or record_id not found

        Example:
            # Update a goal's end date
            result = db.update('goals', record_id=5,
                             updates={'target_date': '2025-12-31'})
        """
        if not updates:
            logger.error("Cannot update with empty updates dict")
            raise ValueError("updates dict cannot be empty")

        # Fetch the current record for archiving
        current_records = self.query(table, filters={'id': record_id})

        if not current_records:
            logger.error(f"Record with id={record_id} not found in {table}")
            raise ValueError(f"No record found with id={record_id} in {table}")

        current_record = current_records[0]

        # Build UPDATE SQL
        set_sql, values = self._build_set_clause(updates)
        sql = f"UPDATE {table} SET {set_sql} WHERE id = ?"
        values.append(record_id)

        logger.info(f"Updating record id={record_id} in {table}")
        logger.debug(f"SQL: {sql}")
        logger.debug(f"Values: {values}")

        with self._get_connection() as conn:
            # Archive old version first if requested
            if archive_old:
                _archive_records(conn, table, [current_record],
                               reason='update', notes=notes)

            # Execute update
            cursor = conn.cursor()
            cursor.execute(sql, values)
            rows_updated = cursor.rowcount

            if rows_updated == 0:
                logger.warning(f"Update affected 0 rows for id={record_id}")

        logger.info(f"✓ Updated record id={record_id} in {table}")

        return {
            'id': record_id,
            'archived': archive_old,
            'updated': rows_updated > 0
        }

    def update_by_uuid(self, table: str, record_uuid: str, updates: dict,
                       archive_old: bool = True, notes: str = '') -> dict:
        """
        Update a record by UUID, optionally archiving the old version.

        Args:
            table: Table name
            record_uuid: The UUID of the record to update (as string)
            updates: Dict of column:value pairs to update
            archive_old: If True, archive the old version before updating (default: True)
            notes: Optional notes for the archive entry

        Returns:
            {
                'uuid_id': str,         # The updated record UUID
                'archived': bool,       # Whether old version was archived
                'updated': bool         # Whether update succeeded
            }

        Raises:
            ValueError: If updates dict is empty or record_uuid not found
        """
        if not updates:
            logger.error("Cannot update with empty updates dict")
            raise ValueError("updates dict cannot be empty")

        # Fetch the current record for archiving
        current_records = self.query(table, filters={'uuid_id': record_uuid})

        if not current_records:
            logger.error(f"Record with uuid_id={record_uuid} not found in {table}")
            raise ValueError(f"No record found with uuid_id={record_uuid} in {table}")

        current_record = current_records[0]

        # Build UPDATE SQL (using uuid_id instead of id)
        set_sql, values = self._build_set_clause(updates)
        sql = f"UPDATE {table} SET {set_sql} WHERE uuid_id = ?"
        values.append(record_uuid)

        logger.info(f"Updating record uuid_id={record_uuid} in {table}")
        logger.debug(f"SQL: {sql}")
        logger.debug(f"Values: {values}")

        with self._get_connection() as conn:
            # Archive old version first if requested
            if archive_old:
                _archive_records(conn, table, [current_record],
                               reason='update', notes=notes)

            # Execute update
            cursor = conn.cursor()
            cursor.execute(sql, values)
            rows_updated = cursor.rowcount

            if rows_updated == 0:
                logger.warning(f"Update affected 0 rows for uuid_id={record_uuid}")

        logger.info(f"✓ Updated record uuid_id={record_uuid} in {table}")

        return {
            'uuid_id': record_uuid,
            'archived': archive_old,
            'updated': rows_updated > 0
        }

    def archive_and_delete(self, table: str, filters: dict,
                          reason: str = 'delete',
                          confirm: bool = False,
                          notes: str = '') -> dict:
        """
        Archive and delete records with preview/confirm workflow.

        Two-step process:
        1. Call with confirm=False to preview what would be deleted
        2. Call with confirm=True to actually archive and delete

        Args:
            table: Table name
            filters: Dict of column:value pairs to identify records
                     Example: {'unit': 'deprecated', 'id': 5}
            reason: Why deleting (logged in archive table)
            confirm: If False, preview only. If True, actually delete.
            notes: Optional additional context for archive

        Returns:
            {
                'count': int,           # Number of records found
                'records': List[dict],  # The actual records (for preview)
                'deleted': bool,        # Whether deletion occurred
                'archived': bool        # Whether archiving occurred
            }

        Example:
            # Step 1: Preview
            result = db.archive_and_delete('goals', {'unit': 'old'}, confirm=False)
            print(f"Would delete {result['count']} records")
            for record in result['records']:
                print(f"  - {record['description']}")

            # Step 2: User confirms, actually delete
            if user_confirms():
                result = db.archive_and_delete('goals', {'unit': 'old'},
                                               confirm=True, reason='cleanup')
        """
        if not filters:
            logger.error("Attempted to delete without filters - would delete ALL records!")
            raise ValueError("Must provide filters to prevent deleting all records")

        # Always query first to see what we're working with
        records = self.query(table, filters)

        if not records:
            logger.info(f"No records found in {table} matching filters: {filters}")
            return {
                'count': 0,
                'records': [],
                'deleted': False,
                'archived': False
            }

        # Preview mode - just return what would happen
        if not confirm:
            logger.info(f"PREVIEW: Would archive/delete {len(records)} records from {table}")
            return {
                'count': len(records),
                'records': records,
                'deleted': False,
                'archived': False
            }

        # Confirmed - actually do it
        logger.warning(f"⚠️  CONFIRMED: Archiving and deleting {len(records)} records from {table}")

        # Use module-level functions within a single transaction
        with self._get_connection() as conn:
            # Archive first
            _archive_records(conn, table, records, reason, notes)

            # Then delete
            _delete_records_unsafe(conn, table, filters)

        return {
            'count': len(records),
            'records': records,
            'deleted': True,
            'archived': True
        }

