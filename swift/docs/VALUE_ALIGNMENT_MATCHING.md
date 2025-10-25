# Value-Goal-Action Alignment Matching Functions

**Last Updated**: 2025-10-24
**Written by**: Claude Code with David Williams
**Status**: Design proposal (not yet implemented)

## Purpose

This document proposes matching functions that connect **Actions**, **Values**, and **Goals** to answer meaningful questions about whether daily activities align with core values. These functions are designed to be informative and encouraging, supporting introspection without judgment.

---

## Table of Contents

1. [Overview](#overview)
2. [Current System Architecture](#current-system-architecture)
3. [Proposed Matching Functions](#proposed-matching-functions)
4. [Implementation Priority](#implementation-priority)
5. [Technical Details](#technical-details)
6. [Future Enhancements](#future-enhancements)

---

## Overview

### The Alignment Question

The fundamental question these functions help answer:

> **"Am I living according to my highest values?"**

And related questions:
- Which values am I actively serving this week?
- Which high-priority values am I neglecting?
- Which actions are most efficient (serving multiple values)?
- Are my current goals aligned with what matters most?

### Design Philosophy

**Encouraging, Not Shaming**:
- Frame dormant values as "opportunities to reconnect" not "failures"
- Celebrate cross-domain actions that serve multiple values simultaneously
- Provide immediate positive reinforcement when logging actions
- Honor the interconnected nature of values (growth serves health, health enables learning)

**Informative, Not Prescriptive**:
- Surface patterns and trends for reflection
- Prioritize based on user's own value hierarchy
- Respect that "steady state" is valid (not everything needs growth)
- Acknowledge intentional choices to deprioritize values temporarily

---

## Current System Architecture

### Existing Relationships

```
Actions ─(action_goal_progress)→ Goals ─(how_goal_is_relevant JSON)→ Values
  ✅ 188 relationships              ✅ JSON-encoded links             ✅ 7 major values
```

### Current Gap

❌ **No direct Action → Value connection**
Can't answer: "Am I living according to my highest values?" without traversing:
```
Action → action_goal_progress → Goal → parse JSON → Value
```

### Data Model Status

**Models exist**:
- ✅ `ActionGoalRelationship` (Sources/Models/Relationships/ActionGoalRelationship.swift)
- ✅ `GoalValueAlignment` (Sources/Models/Relationships/GoalValueAlignment.swift)

**Database tables**:
- ✅ `action_goal_progress` table (operational, 188 relationships)
- ❌ `goal_value_alignment` table (schema exists, not populated)

**Current JSON storage** (in `goals` table):
```json
{
  "how_goal_is_relevant": {
    "major_values": ["Continuous Learning", "Holistic Cultivation"],
    "life_areas": ["learning", "hobbies"]
  }
}
```

---

## Proposed Matching Functions

### Function 1: Value Fulfillment Score 📊

**Purpose**: Show how much you're honoring each value through daily actions

**What it answers**: "Which values am I actively serving?"

#### Algorithm

```sql
-- For each value, calculate weekly "activation score"
WITH value_actions AS (
  SELECT
    v.uuid_id as value_id,
    v.title as value_name,
    v.priority,
    COUNT(DISTINCT a.uuid_id) as action_count,
    SUM(agp.contribution) as total_contribution
  FROM personal_values v
  LEFT JOIN goals g
    ON json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
  LEFT JOIN action_goal_progress agp ON g.uuid_id = agp.goal_id
  LEFT JOIN actions a ON agp.action_id = a.uuid_id
  WHERE a.log_time >= date('now', '-7 days')
  GROUP BY v.uuid_id
)
SELECT
  value_name,
  priority,
  action_count,
  ROUND(action_count * 1.0 / priority * 100, 1) as fulfillment_score
FROM value_actions
ORDER BY priority DESC;
```

#### Example Output

| Value Name | Priority | Action Count | Fulfillment Score |
|------------|----------|--------------|-------------------|
| Equanimity, Peace, Freedom from Suffering | 95 | 12 | 12.6% |
| Continuous Learning | 90 | 18 | 20.0% |
| Physical Health | 85 | 15 | 17.6% |
| Companionship with Solène | 88 | 8 | 9.1% |

#### Why It's Encouraging

- **Celebrates congruent living**: High scores = you're walking your talk
- **Gentle nudges**: High-priority values with low scores suggest realignment opportunity
- **Normalizes fluctuation**: Values naturally ebb and flow week-to-week
- **Honors intentionality**: Low score might be intentional (e.g., focusing on one area this term)

---

### Function 2: Cross-Domain Action Detection 🎯

**Purpose**: Highlight actions that serve multiple values simultaneously

**What it answers**: "Which actions give me the most bang for my buck?"

#### Algorithm

```sql
-- Find actions that contribute to goals linked to different values
WITH action_value_count AS (
  SELECT
    a.uuid_id as action_id,
    a.title as action_name,
    a.log_time,
    COUNT(DISTINCT v.uuid_id) as value_count,
    GROUP_CONCAT(DISTINCT v.title, ' + ') as values_served
  FROM actions a
  JOIN action_goal_progress agp ON a.uuid_id = agp.action_id
  JOIN goals g ON agp.goal_id = g.uuid_id
  JOIN personal_values v
    ON json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
  GROUP BY a.uuid_id
  HAVING value_count > 1
)
SELECT
  action_name,
  value_count,
  values_served,
  date(log_time) as when_logged
FROM action_value_count
ORDER BY value_count DESC, log_time DESC
LIMIT 20;
```

#### Example Output

| Action | Values Served | Count |
|--------|---------------|-------|
| Running together with Solène | Physical Health + Companionship with Solène + Mental Health | 3 |
| Yoga with Jessica | Physical Health + Mental Health | 2 |
| Writing essays | Continuous Learning + Mental Health + Holistic Cultivation | 3 |

#### Why It's Encouraging

- **Celebrates efficiency**: One activity, multiple benefits
- **Suggests design patterns**: "Combining physical activity with quality time works!"
- **Honors interconnection**: Values naturally support each other
- **Inspires creativity**: "What other combinations could I design?"

---

### Function 3: Value Neglect Alert ⚠️

**Purpose**: Gently surface values that haven't been activated recently

**What it answers**: "Which values need attention?"

#### Algorithm

```sql
WITH recent_value_activity AS (
  SELECT
    v.uuid_id,
    v.title,
    v.priority,
    MAX(a.log_time) as last_action_date,
    julianday('now') - julianday(MAX(a.log_time)) as days_since_last_action
  FROM personal_values v
  LEFT JOIN goals g
    ON json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
  LEFT JOIN action_goal_progress agp ON g.uuid_id = agp.goal_id
  LEFT JOIN actions a ON agp.action_id = a.uuid_id
  WHERE v.incentive_type = 'major'
  GROUP BY v.uuid_id
)
SELECT
  title,
  priority,
  COALESCE(ROUND(days_since_last_action), 999) as days_dormant,
  CASE
    WHEN days_since_last_action IS NULL THEN '🔴 Never activated (no goals yet)'
    WHEN days_since_last_action > 14 THEN '🔴 Urgent attention (2+ weeks)'
    WHEN days_since_last_action > 7 THEN '🟡 Consider this week'
    ELSE '🟢 Recently honored'
  END as status
FROM recent_value_activity
ORDER BY priority DESC, days_since_last_action DESC;
```

#### Example Output

| Value | Priority | Days Dormant | Status |
|-------|----------|--------------|--------|
| Equanimity, Peace, Freedom | 95 | 999 | 🔴 Never activated (no goals yet) |
| Economic Health | 80 | 21 | 🔴 Urgent attention (2+ weeks) |
| Companionship with Solène | 88 | 3 | 🟢 Recently honored |

#### Why It's Encouraging (Not Shaming)

- **Framed as opportunity**: "Opportunity to reconnect" vs "you're failing"
- **Respects priority**: High-priority values flagged first
- **Normalizes rhythm**: Values naturally cycle in/out of focus
- **Prompts reflection**: "Is this intentional or accidental neglect?"
- **Actionable**: Suggests when rebalancing might be helpful

---

### Function 4: Goal-Value Alignment Verification 🔍

**Purpose**: Ensure current goals actually serve stated values

**What it answers**: "Do my goals reflect what matters most?"

#### Algorithm

```sql
-- Check if high-priority values have active goals
WITH value_goal_coverage AS (
  SELECT
    v.uuid_id,
    v.title as value_name,
    v.priority,
    COUNT(DISTINCT g.uuid_id) as active_goals,
    GROUP_CONCAT(g.title, ', ') as goal_list
  FROM personal_values v
  LEFT JOIN goals g ON (
    json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
    AND g.target_date >= date('now')
  )
  WHERE v.incentive_type = 'major'
  GROUP BY v.uuid_id
)
SELECT
  value_name,
  priority,
  active_goals,
  CASE
    WHEN active_goals = 0 AND priority >= 90
      THEN '⚠️  High-priority value needs goals!'
    WHEN active_goals = 0
      THEN '💡 Consider adding goals'
    ELSE '✅ ' || active_goals || ' active goal(s)'
  END as status,
  goal_list
FROM value_goal_coverage
ORDER BY priority DESC;
```

#### Example Output

| Value | Priority | Status | Goals |
|-------|----------|--------|-------|
| Equanimity, Peace, Freedom | 95 | ⚠️ High-priority value needs goals! | (none) |
| Continuous Learning | 90 | ✅ 2 active goals | Programming II, Write for Public Audience |
| Physical Health | 85 | ✅ 2 active goals | Yoga/Mobility, Running |

#### Why It's Informative

- **Reveals strategic gaps**: "Equanimity is #1 priority but has no goals - interesting!"
- **Prompts intentional planning**: "What should next 10-week term focus on?"
- **Honors implicit values**: Some values (like Equanimity) might not need measurable goals
- **Supports reflection**: "Is this value implicit in other goals, or truly neglected?"

#### Special Case: Values Without Measurable Goals

**Insight**: Not all values need explicit goals.

Example: **"Equanimity, Peace, Freedom from Suffering"** (priority 95)
- This might be a **way of being** rather than a **target to achieve**
- Could be implicit in HOW you pursue other goals (e.g., learning without stress, running for peace)
- Absence of goals isn't necessarily a problem - might need different tracking (reflection prompts, mood tracking)

**Algorithm Enhancement** (future):
```sql
-- Identify values that might be "ways of being" vs "things to achieve"
SELECT
  v.title,
  v.priority,
  CASE
    WHEN v.description LIKE '%way of%' OR v.description LIKE '%approach%'
      THEN 'Way of being (may not need explicit goals)'
    ELSE 'Outcome-oriented (should have goals)'
  END as value_type
FROM personal_values v;
```

---

### Function 5: Value Momentum Tracker 📈

**Purpose**: Show trends over time - moving toward or away from each value?

**What it answers**: "Am I making progress on what matters?"

#### Algorithm

```sql
-- Compare last 7 days vs previous 7 days
WITH this_week AS (
  SELECT
    v.uuid_id,
    COUNT(DISTINCT a.uuid_id) as action_count_this_week
  FROM personal_values v
  LEFT JOIN goals g
    ON json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
  LEFT JOIN action_goal_progress agp ON g.uuid_id = agp.goal_id
  LEFT JOIN actions a ON agp.action_id = a.uuid_id
  WHERE a.log_time >= date('now', '-7 days')
  GROUP BY v.uuid_id
),
last_week AS (
  SELECT
    v.uuid_id,
    COUNT(DISTINCT a.uuid_id) as action_count_last_week
  FROM personal_values v
  LEFT JOIN goals g
    ON json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
  LEFT JOIN action_goal_progress agp ON g.uuid_id = agp.goal_id
  LEFT JOIN actions a ON agp.action_id = a.uuid_id
  WHERE a.log_time >= date('now', '-14 days')
    AND a.log_time < date('now', '-7 days')
  GROUP BY v.uuid_id
)
SELECT
  v.title,
  v.priority,
  COALESCE(tw.action_count_this_week, 0) as this_week,
  COALESCE(lw.action_count_last_week, 0) as last_week,
  COALESCE(tw.action_count_this_week, 0) - COALESCE(lw.action_count_last_week, 0) as change,
  CASE
    WHEN tw.action_count_this_week > lw.action_count_last_week THEN '📈 Growing'
    WHEN tw.action_count_this_week < lw.action_count_last_week THEN '📉 Declining'
    ELSE '→ Steady'
  END as momentum
FROM personal_values v
LEFT JOIN this_week tw ON v.uuid_id = tw.uuid_id
LEFT JOIN last_week lw ON v.uuid_id = lw.uuid_id
WHERE v.incentive_type = 'major'
ORDER BY v.priority DESC;
```

#### Example Output

| Value | Priority | This Week | Last Week | Change | Momentum |
|-------|----------|-----------|-----------|--------|----------|
| Continuous Learning | 90 | 18 | 12 | +6 | 📈 Growing |
| Physical Health | 85 | 15 | 16 | -1 | 📉 Declining |
| Companionship | 88 | 8 | 8 | 0 | → Steady |

#### Why It's Encouraging

- **Progress feels good**: Even small improvements are celebrated
- **Prompts reflection on declines**: "Is this intentional or drift?"
- **Normalizes steady state**: Not everything needs constant growth
- **Reveals patterns**: "Learning always grows when I have a project"
- **Supports course correction**: Early warning system for unintended drift

---

### Function 6: Action-Value Attribution 🏷️

**Purpose**: When logging an action, immediately show which values it serves

**What it answers**: "Why does this action matter?"

#### Algorithm

```sql
-- For a given action, show value attribution
SELECT DISTINCT
  v.title as value,
  v.priority,
  g.title as via_goal,
  agp.contribution || ' ' || g.measurement_unit as contribution
FROM action_goal_progress agp
JOIN goals g ON agp.goal_id = g.uuid_id
JOIN personal_values v
  ON json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
WHERE agp.action_id = ?  -- The action just logged
ORDER BY v.priority DESC;
```

#### Example UI Flow

**User logs**: "30 minutes yoga"

**System responds**:
```
✨ Great work! This action serves:

🟣 Physical Health and Longevity (priority 85)
   via "Yoga, Mobility, and Strength" goal
   Contribution: 30 minutes

🔵 Mental Health and Longevity (priority 87)
   via "Write More" goal (stress reduction)
   Contribution: 30 minutes

Keep it up! You've honored 2 major values today.
```

#### Why It's Encouraging

- **Immediate positive reinforcement**: Connect action to meaning
- **Makes values tangible**: Not abstract principles, lived reality
- **Celebrates multi-value actions**: "This yoga session served 2 values!"
- **Builds motivation**: "I'm not just exercising, I'm serving Physical Health"
- **Creates positive feedback loop**: Feel good → do more → serve values

---

## Implementation Priority

### Recommended Sequence

If implementing these functions, suggested order:

**Phase 1: Foundation (Weeks 1-2)**
1. **Migrate JSON to `goal_value_alignment` table**
   - Parse existing `how_goal_is_relevant` JSON
   - Create `GoalValueAlignment` records
   - Keep JSON as backup during migration

2. **Function 6: Action-Value Attribution** (real-time feedback)
   - Implement as action logging enhancement
   - Provides immediate user value
   - Tests the relationship data flow

**Phase 2: Dashboard (Weeks 3-4)**
3. **Function 1: Value Fulfillment Score** (dashboard headline)
   - Weekly summary view
   - Visual progress bars per value
   - Sortable by priority/fulfillment

4. **Function 3: Value Neglect Alert** (weekly review)
   - Gentle reminder system
   - Framed as "opportunities to reconnect"
   - Optional notifications

**Phase 3: Insights (Week 5)**
5. **Function 2: Cross-Domain Actions** (celebrate efficiency)
   - Weekly "highlight reel"
   - Shows high-leverage behaviors
   - Suggests design patterns

6. **Function 4: Goal-Value Alignment** (strategic planning)
   - Term planning tool
   - Identifies gaps before setting goals
   - Supports intentional focus

**Phase 4: Advanced (Week 6+)**
7. **Function 5: Value Momentum** (long-term trends)
   - Requires 3+ weeks of data
   - Monthly reflection tool
   - Charts and visualizations

---

## Technical Details

### Database Schema Requirements

#### Existing Tables (already implemented)
```sql
-- personal_values table
CREATE TABLE personal_values (
  uuid_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  incentive_type TEXT NOT NULL,  -- 'major', 'minor', etc.
  priority INTEGER NOT NULL DEFAULT 50,
  life_domain TEXT,
  ...
);

-- goals table (with JSON value links)
CREATE TABLE goals (
  uuid_id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  how_goal_is_relevant TEXT,  -- JSON: {"major_values": [...], "life_areas": [...]}
  ...
);

-- action_goal_progress table (operational)
CREATE TABLE action_goal_progress (
  uuid_id TEXT PRIMARY KEY,
  action_id TEXT NOT NULL,
  goal_id TEXT NOT NULL,
  contribution REAL,
  match_method TEXT,
  ...
);
```

#### Required Migration

**Create `goal_value_alignment` table** (schema exists, needs population):
```sql
CREATE TABLE IF NOT EXISTS goal_value_alignment (
  uuid_id TEXT PRIMARY KEY,
  goal_id TEXT NOT NULL,
  value_id TEXT NOT NULL,
  alignment_strength REAL NOT NULL,
  assignment_method TEXT NOT NULL,
  confidence REAL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (goal_id) REFERENCES goals(uuid_id) ON DELETE CASCADE,
  FOREIGN KEY (value_id) REFERENCES personal_values(uuid_id) ON DELETE CASCADE,
  UNIQUE(goal_id, value_id)
);
```

**Migration script** (parse existing JSON):
```sql
-- Extract value names from goals.how_goal_is_relevant JSON
-- Create goal_value_alignment records
-- Map value names to personal_values.uuid_id via title matching

INSERT INTO goal_value_alignment (uuid_id, goal_id, value_id, alignment_strength, assignment_method, confidence)
SELECT
  lower(hex(randomblob(16))) as uuid_id,
  g.uuid_id as goal_id,
  v.uuid_id as value_id,
  0.9 as alignment_strength,  -- High strength (manually curated)
  'manual' as assignment_method,
  1.0 as confidence
FROM goals g
JOIN personal_values v ON
  json_extract(g.how_goal_is_relevant, '$.major_values') LIKE '%' || v.title || '%'
WHERE g.how_goal_is_relevant IS NOT NULL;
```

### Swift Implementation Sketch

```swift
// Sources/BusinessLogic/ValueFulfillmentService.swift

import Foundation
import GRDB

@MainActor
class ValueFulfillmentService {
    private let database: DatabaseManager

    init(database: DatabaseManager) {
        self.database = database
    }

    /// Calculate fulfillment score for each value
    func calculateFulfillmentScores(timeWindow: TimeWindow = .lastWeek) async throws -> [ValueFulfillment] {
        // SQL query from Function 1
        // Returns array of ValueFulfillment structs
    }

    /// Find cross-domain actions (serving multiple values)
    func findCrossDomainActions(limit: Int = 20) async throws -> [CrossDomainAction] {
        // SQL query from Function 2
    }

    /// Check for neglected values
    func checkValueNeglect() async throws -> [ValueStatus] {
        // SQL query from Function 3
    }

    /// Verify goal-value alignment
    func verifyGoalAlignment() async throws -> [ValueCoverage] {
        // SQL query from Function 4
    }

    /// Calculate momentum trends
    func calculateMomentum() async throws -> [ValueMomentum] {
        // SQL query from Function 5
    }

    /// Get value attribution for specific action
    func getValueAttribution(for actionId: UUID) async throws -> [ValueContribution] {
        // SQL query from Function 6
    }
}

// Supporting types
struct ValueFulfillment {
    let valueName: String
    let priority: Int
    let actionCount: Int
    let fulfillmentScore: Double
}

struct CrossDomainAction {
    let actionName: String
    let valueCount: Int
    let valuesServed: [String]
    let loggedAt: Date
}

// ... etc
```

---

## Future Enhancements

### 1. Automated Value Inference

**Challenge**: "Equanimity" has no goals yet can't be inferred from JSON

**Solution**: Infer from action patterns
```sql
-- Example: Meditation actions might serve Equanimity
-- even without explicit goal connection
SELECT DISTINCT v.uuid_id, v.title
FROM personal_values v, actions a
WHERE a.title LIKE '%meditat%'
  AND v.title LIKE '%Equanimity%'
  AND NOT EXISTS (
    SELECT 1 FROM goal_value_alignment gva
    JOIN action_goal_progress agp ON gva.goal_id = agp.goal_id
    WHERE agp.action_id = a.uuid_id
      AND gva.value_id = v.uuid_id
  );
```

### 2. Value Conflict Detection

**Purpose**: Identify when goals compete for same resources

**Example**:
- "Work 50 hours/week" (Economic Health)
- "Spend 20 hours/week with Solène" (Companionship)
- Total: 70 hours - potential conflict!

```sql
-- Detect time budget conflicts
WITH goal_time_requirements AS (
  SELECT
    g.uuid_id,
    g.title,
    g.measurement_target as hours_needed,
    v.title as value_served
  FROM goals g
  JOIN goal_value_alignment gva ON g.uuid_id = gva.goal_id
  JOIN personal_values v ON gva.value_id = v.uuid_id
  WHERE g.measurement_unit = 'hours'
    AND g.target_date >= date('now')
)
SELECT
  SUM(hours_needed) as total_hours_committed,
  GROUP_CONCAT(title, ', ') as competing_goals
FROM goal_time_requirements
HAVING total_hours_committed > 168;  -- 168 hours/week
```

### 3. Value Balance Visualization

**UI Mockup**: Radar chart showing fulfillment across all values
```
     Equanimity (95)
            /\
           /  \
          /    \
Learning /      \ Physical
  (90)  /        \  (85)
       /          \
      /            \
     /              \
    /_Economic (80)_\
```

Each axis: 0-100% fulfillment relative to priority

### 4. Reflection Prompts

**Triggered by patterns**:
- Value dormant >14 days: "How might you honor [Value] this week?"
- High fulfillment score: "What's working well with [Value] lately?"
- Declining momentum: "Is the decline in [Value] intentional?"
- New cross-domain action: "You found an efficient pattern! How can you repeat this?"

### 5. Value-Based Goal Suggestions

**Use case**: Starting new term, need goal ideas

**Algorithm**:
```sql
-- Find values with low coverage
-- Suggest goal types that match their life_domain
-- Provide templates from successful past goals

WITH underserved_values AS (
  SELECT v.uuid_id, v.title, v.life_domain
  FROM personal_values v
  LEFT JOIN goal_value_alignment gva ON v.uuid_id = gva.value_id
  WHERE gva.uuid_id IS NULL
    AND v.priority >= 85
)
SELECT
  uv.title as value_needing_goals,
  g.title as example_goal_from_past,
  g.measurement_unit as suggested_metric
FROM underserved_values uv
JOIN personal_values v2 ON uv.life_domain = v2.life_domain
JOIN goal_value_alignment gva ON v2.uuid_id = gva.value_id
JOIN goals g ON gva.goal_id = g.uuid_id
LIMIT 5;
```

---

## Appendix: Example User Journey

### Week 1: Discovery

**Monday**: User opens app
- Dashboard shows Value Fulfillment Scores
- Notices "Equanimity" (95 priority) has 0% fulfillment
- Reflects: "I haven't thought about this value in goal-setting"

**Tuesday**: User logs "30 minutes meditation"
- Action-Value Attribution shows:
  ```
  ✨ This action serves:
  🟣 Equanimity, Peace, Freedom from Suffering (priority 95)
     No goal connected yet - consider adding one!
  ```
- User creates goal: "Meditate 10x this term" linked to Equanimity

**Friday**: Weekly review
- Value Neglect Alert shows:
  ```
  🟡 Economic Health (priority 80) - 9 days dormant
     Consider this week: Review budget, update financial plan
  ```
- User realizes they've been avoiding finances
- Logs "1 hour budget review" → serves Economic Health value

### Week 2: Pattern Recognition

**Wednesday**: Cross-Domain Actions highlights:
```
🌟 Top multi-value actions this week:
1. Running with Solène (3 values)
2. Writing essays (3 values)
3. Yoga (2 values)

Pattern detected: Activities with Solène consistently serve multiple values.
Consider: What other shared activities could you try?
```

**Sunday**: Value Momentum shows:
```
📈 Growing: Physical Health (+5 actions)
📉 Declining: Continuous Learning (-3 actions)

Reflection prompt: Is the learning decline intentional (busy week)
or drift (lost focus)?
```

User realizes: "I got busy with work, didn't make time for learning. That's unintentional - I'll prioritize it next week."

### Week 4: Strategic Planning

**New Term Planning**: Goal-Value Alignment Verification shows:
```
⚠️ Gaps identified:
- Equanimity (95): 1 goal (meditate 10x) ← Could use more goals
- Mental Health (87): 1 goal (write more) ← Adequate
- Economic Health (80): 0 goals ← High priority, no focus!

Suggestion: Next term, consider goal for Economic Health
(e.g., "Build 3-month emergency fund" or "Increase income 10%")
```

User creates new goal for Term 3: "Save $5000 emergency fund"

---

**End of Document**

These matching functions provide a complete system for connecting daily actions to deep values, making abstract principles tangible and supporting value-aligned living through gentle, encouraging feedback.