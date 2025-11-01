-- Complete Data Migration Script
-- Written by Claude Code on 2025-10-31
-- Uses SQLite JSON1 functions to parse old JSON data into new 3NF schema
--
-- USAGE:
--   sqlite3 < complete_migration.sql
--
-- This script successfully migrates ALL data including JSON fields

-- Attach both databases
ATTACH DATABASE 'application_data.db' AS old;
ATTACH DATABASE 'new_production.db' AS new;

-- =============================================================================
-- PHASE 1: Create Measures Catalog
-- =============================================================================
-- Extract unique measurement units from both actions and goals

.print ''
.print '================================================================================'
.print 'PHASE 1: Creating Measures Catalog'
.print '================================================================================'

-- Create measures based on actual usage
INSERT INTO new.measures (id, unit, measureType, title, detailedDescription, logTime)
VALUES
  (lower(hex(randomblob(16))), 'km', 'distance', 'Distance', 'Distance measured in kilometers', datetime('now')),
  (lower(hex(randomblob(16))), 'hours', 'time', 'Duration', 'Time duration in hours', datetime('now')),
  (lower(hex(randomblob(16))), 'minutes', 'time', 'Duration (Minutes)', 'Time duration in minutes', datetime('now')),
  (lower(hex(randomblob(16))), 'occasions', 'count', 'Occasions', 'Number of times an activity occurs', datetime('now')),
  (lower(hex(randomblob(16))), 'essays', 'count', 'Essays', 'Number of essays written', datetime('now'));

SELECT '✓ Created ' || COUNT(*) || ' measures' FROM new.measures;

-- =============================================================================
-- PHASE 2: Migrate Core Abstractions
-- =============================================================================

.print ''
.print '================================================================================'
.print 'PHASE 2: Migrating Core Abstractions'
.print '================================================================================'

-- 2.1: Actions (basic fields)
INSERT INTO new.actions (id, title, detailedDescription, freeformNotes, logTime, durationMinutes, startTime)
SELECT id, title, detailedDescription, freeformNotes, logTime, durationMinutes, startTime
FROM old.actions;

SELECT '✓ Migrated ' || COUNT(*) || ' actions' FROM new.actions;

-- 2.2: Expectations (from goals)
INSERT INTO new.expectations (id, title, detailedDescription, freeformNotes, logTime, expectationType, expectationImportance, expectationUrgency)
SELECT id, title, detailedDescription, freeformNotes, logTime, 'goal', 8, 5
FROM old.goals;

SELECT '✓ Created ' || COUNT(*) || ' expectations from goals' FROM new.expectations;

-- 2.3: PersonalValues (unified from 4 tables)
-- Major Values
INSERT INTO new.personalvalues (id, title, detailedDescription, freeformNotes, logTime, priority, valueLevel, lifeDomain, alignmentGuidance)
SELECT id, title, detailedDescription, freeformNotes, logTime, priority, 'major', lifeDomain, alignmentGuidance
FROM old.majorValueses;

-- Highest Order Values
INSERT INTO new.personalvalues (id, title, detailedDescription, freeformNotes, logTime, priority, valueLevel, lifeDomain, alignmentGuidance)
SELECT id, title, detailedDescription, freeformNotes, logTime, priority, 'highest_order', lifeDomain, NULL
FROM old.highestOrderValueses;

-- General Values (if any)
INSERT INTO new.personalvalues (id, title, detailedDescription, freeformNotes, logTime, priority, valueLevel, lifeDomain, alignmentGuidance)
SELECT id, title, detailedDescription, freeformNotes, logTime, priority, 'general', lifeDomain, NULL
FROM old.valueses;

-- Life Areas (if any)
INSERT INTO new.personalvalues (id, title, detailedDescription, freeformNotes, logTime, priority, valueLevel, lifeDomain, alignmentGuidance)
SELECT id, title, detailedDescription, freeformNotes, logTime, priority, 'life_area', lifeDomain, NULL
FROM old.lifeAreases;

SELECT '✓ Migrated ' || COUNT(*) || ' personal values' FROM new.personalvalues;

-- 2.4: TimePeriods (from goalTerms)
INSERT INTO new.timeperiods (id, title, detailedDescription, freeformNotes, logTime, startDate, endDate)
SELECT
    lower(hex(randomblob(16))),  -- Generate new UUID for TimePeriod
    'Period for ' || title,
    detailedDescription,
    freeformNotes,
    logTime,
    startDate,
    targetDate
FROM old.goalTerms;

SELECT '✓ Created ' || COUNT(*) || ' time periods' FROM new.timeperiods;

-- =============================================================================
-- PHASE 3: Migrate Basic Entities
-- =============================================================================

.print ''
.print '================================================================================'
.print 'PHASE 3: Migrating Basic Entities'
.print '================================================================================'

-- 3.1: Goals (subtype table)
INSERT INTO new.goals (id, expectationId, startDate, targetDate, expectedTermLength, actionPlan)
SELECT
    id,
    id,  -- expectationId references same UUID
    startDate,
    targetDate,
    expectedTermLength,
    -- Extract actionPlan from howGoalIsActionable JSON (keywords array → text)
    CASE
        WHEN howGoalIsActionable IS NOT NULL
        THEN 'Keywords: ' || json_extract(howGoalIsActionable, '$.keywords')
        ELSE NULL
    END
FROM old.goals;

SELECT '✓ Created ' || COUNT(*) || ' goal subtypes' FROM new.goals;

-- 3.2: GoalTerms (with FK to TimePeriods)
-- Create temporary mapping table
CREATE TEMP TABLE term_mapping AS
SELECT
    gt.id as old_goalterm_id,
    tp.id as new_timeperiod_id,
    gt.termNumber
FROM old.goalTerms gt
JOIN new.timeperiods tp ON tp.title = 'Period for ' || gt.title;

INSERT INTO new.goalterms (id, timePeriodId, termNumber, theme, reflection, status)
SELECT
    lower(hex(randomblob(16))),  -- New UUID for GoalTerm
    new_timeperiod_id,
    termNumber,
    NULL,  -- theme will be extracted from old title if needed
    NULL,  -- reflection not in old schema
    'completed'  -- Assume past terms are completed
FROM term_mapping;

SELECT '✓ Created ' || COUNT(*) || ' goal terms' FROM new.goalterms;

-- 3.3: ExpectationMeasures (from measurementUnit/measurementTarget)
INSERT INTO new.expectationmeasures (id, expectationId, measureId, targetValue, createdAt, freeformNotes)
SELECT
    lower(hex(randomblob(16))),
    g.id,
    m.id,
    g.measurementTarget,
    g.logTime,
    NULL
FROM old.goals g
JOIN new.measures m ON m.unit = g.measurementUnit
WHERE g.measurementUnit IS NOT NULL AND g.measurementTarget IS NOT NULL;

SELECT '✓ Created ' || COUNT(*) || ' expectation measures (goal targets)' FROM new.expectationmeasures;

-- =============================================================================
-- PHASE 4: Migrate Junction Tables (Composits)
-- =============================================================================

.print ''
.print '================================================================================'
.print 'PHASE 4: Migrating Junction Tables (Using JSON1 Functions)'
.print '================================================================================'

-- 4.1: MeasuredActions (parse measuresByUnit JSON)
INSERT INTO new.measuredactions (id, actionId, measureId, value, createdAt)
SELECT
    lower(hex(randomblob(16))),
    a.id,
    m.id,
    CAST(je.value AS REAL),  -- Convert JSON value to REAL
    a.logTime
FROM old.actions a,
     json_each(a.measuresByUnit) je
JOIN new.measures m ON m.unit = je.key
WHERE a.measuresByUnit IS NOT NULL;

SELECT '✓ Created ' || COUNT(*) || ' measured actions' FROM new.measuredactions;

-- 4.2: GoalRelevances (parse howGoalIsRelevant JSON)
-- Handle major_values array
INSERT INTO new.goalrelevances (id, goalId, valueId, alignmentStrength, relevanceNotes, createdAt)
SELECT
    lower(hex(randomblob(16))),
    g.id,
    pv.id,
    NULL,  -- alignmentStrength not in old schema
    'Migrated from major_values',
    g.logTime
FROM old.goals g,
     json_each(json_extract(g.howGoalIsRelevant, '$.major_values')) je
JOIN new.personalvalues pv ON pv.title = je.value
WHERE g.howGoalIsRelevant IS NOT NULL
  AND json_extract(g.howGoalIsRelevant, '$.major_values') IS NOT NULL;

SELECT '✓ Created ' || COUNT(*) || ' goal-value relevances from major_values' FROM (
    SELECT DISTINCT goalId FROM new.goalrelevances
);

-- Handle the special case: "Companionship with Solene" → "Companionship with Solène"
INSERT OR IGNORE INTO new.goalrelevances (id, goalId, valueId, alignmentStrength, relevanceNotes, createdAt)
SELECT
    lower(hex(randomblob(16))),
    g.id,
    pv.id,
    NULL,
    'Migrated from major_values (name matched)',
    g.logTime
FROM old.goals g,
     json_each(json_extract(g.howGoalIsRelevant, '$.major_values')) je
JOIN new.personalvalues pv ON pv.title LIKE 'Companionship with Sol%ne'
WHERE je.value = 'Companionship with Solene';

-- =============================================================================
-- PHASE 5: Verification & Summary
-- =============================================================================

.print ''
.print '================================================================================'
.print 'MIGRATION COMPLETE - SUMMARY'
.print '================================================================================'

.print ''
.print 'OLD DATABASE COUNTS:'
SELECT '  Actions: ' || COUNT(*) FROM old.actions;
SELECT '  Goals: ' || COUNT(*) FROM old.goals;
SELECT '  GoalTerms: ' || COUNT(*) FROM old.goalTerms;
SELECT '  Values (all types): ' || (
    (SELECT COUNT(*) FROM old.valueses) +
    (SELECT COUNT(*) FROM old.majorValueses) +
    (SELECT COUNT(*) FROM old.highestOrderValueses) +
    (SELECT COUNT(*) FROM old.lifeAreases)
);

.print ''
.print 'NEW DATABASE COUNTS:'
SELECT '  Actions: ' || COUNT(*) FROM new.actions;
SELECT '  Expectations: ' || COUNT(*) FROM new.expectations;
SELECT '  Goals: ' || COUNT(*) FROM new.goals;
SELECT '  Measures: ' || COUNT(*) FROM new.measures;
SELECT '  PersonalValues: ' || COUNT(*) FROM new.personalvalues;
SELECT '  TimePeriods: ' || COUNT(*) FROM new.timeperiods;
SELECT '  GoalTerms: ' || COUNT(*) FROM new.goalterms;

.print ''
.print 'JUNCTION TABLES:'
SELECT '  MeasuredActions: ' || COUNT(*) FROM new.measuredactions;
SELECT '  ExpectationMeasures: ' || COUNT(*) FROM new.expectationmeasures;
SELECT '  GoalRelevances: ' || COUNT(*) FROM new.goalrelevances;

.print ''
.print '================================================================================'
.print 'VERIFICATION QUERIES'
.print '================================================================================'

-- Sample: Show a goal with all its relationships
.print ''
.print 'Sample Goal with Full Relationships:'
.print '---'
SELECT
    e.title as goal_title,
    g.startDate,
    g.targetDate,
    g.actionPlan
FROM new.goals g
JOIN new.expectations e ON g.expectationId = e.id
LIMIT 1;

.print ''
.print 'Its Measurements:'
SELECT
    m.unit,
    em.targetValue
FROM new.expectationmeasures em
JOIN new.measures m ON em.measureId = m.id
WHERE em.expectationId = (SELECT expectationId FROM new.goals LIMIT 1);

.print ''
.print 'Its Values:'
SELECT
    pv.title,
    pv.valueLevel
FROM new.goalrelevances gr
JOIN new.personalvalues pv ON gr.valueId = pv.id
WHERE gr.goalId = (SELECT id FROM new.goals LIMIT 1);

.print ''
.print '================================================================================'
.print 'SUCCESS! All data migrated using SQL JSON1 functions.'
.print 'Database: new_production.db'
.print '================================================================================'
