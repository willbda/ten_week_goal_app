-- Actions Table
CREATE TABLE actions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT NOT NULL,
    log_time TEXT,
    measurements TEXT,
    start_time TEXT,
    duration_minutes REAL
    );