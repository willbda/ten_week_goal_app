

-- -- Goals table: 10-week objectives and targets
-- CREATE TABLE goals (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   label TEXT UNIQUE,                    -- '202504-Learning'
--   title TEXT NOT NULL,                  -- 'spend 40 hours reading...'
--   target_value REAL,                    -- 40
--   unit TEXT,                            -- 'hours spent'
--   start_date TEXT,                      -- '2025-04-12'
--   end_date TEXT,                        -- '2025-06-21'
--   term_length_weeks INTEGER,            -- 10
--   created_at TEXT DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Entries table: daily progress logs
-- CREATE TABLE entries (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   goal_id INTEGER NOT NULL,
--   date TEXT NOT NULL,                   -- '2025-04-15'
--   value REAL,                           -- 0.5
--   description TEXT,                     -- 'GoogleScript spreadsheet coding'
--   created_at TEXT DEFAULT CURRENT_TIMESTAMP,
--   FOREIGN KEY (goal_id) REFERENCES goals(id)
-- );

-- -- Values alignment ratings: how well activities align with core values
-- CREATE TABLE values_ratings (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   entry_id INTEGER NOT NULL,
--   value_name TEXT NOT NULL,             -- 'continuous_learning', 'live_well', etc.
--   rating INTEGER CHECK (rating >= 1 AND rating <= 5),
--   notes TEXT,                           -- Optional explanation
--   FOREIGN KEY (entry_id) REFERENCES entries(id)
-- );

-- -- Create indexes for better query performance
-- CREATE INDEX idx_entries_goal_id ON entries(goal_id);
-- CREATE INDEX idx_entries_date ON entries(date);
-- CREATE INDEX idx_values_entry_id ON values_ratings(entry_id);
-- CREATE INDEX idx_values_name ON values_ratings(value_name);


-- -- Useful queries for getting started

-- -- View all goals with current progress
-- -- SELECT 
-- --   g.label,
-- --   g.title,
-- --   g.target_value,
-- --   SUM(e.value) as current_progress,
-- --   ROUND(SUM(e.value) / g.target_value * 100, 1) as percentage_complete
-- -- FROM goals g
-- -- LEFT JOIN entries e ON g.id = e.goal_id
-- -- GROUP BY g.id;

-- -- Recent activity across all goals
-- -- SELECT 
-- --   g.label,
-- --   e.date,
-- --   e.value,
-- --   e.description
-- -- FROM entries e
-- -- JOIN goals g ON e.goal_id = g.id
-- -- ORDER BY e.date DESC
-- -- LIMIT 10;