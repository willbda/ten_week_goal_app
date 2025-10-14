# Values Quick Start Guide

A practical guide to adding your personal values to the Ten Week Goal App.

## What Are Personal Values?

The system supports four types of incentives, representing different levels of abstraction and commitment:

1. **Major Values** - Actionable values requiring regular tracking with alignment guidance (e.g., "Health & Vitality")
2. **Highest Order Values** - Abstract philosophical principles that guide everything (e.g., "Flourishing")
3. **Life Areas** - Organizational domains (importantly, NOT values) (e.g., "Career Development")
4. **General Values** - Aspirational values not necessarily tracked regularly (e.g., "Kindness")

**Important Distinction:** Life Areas help explain why goals matter without implying they are valued. Your career might guide decisions without you necessarily "valuing" it as a core principle.

## New Architecture: Type-Specific Commands

Instead of a single `values create` command with a `--type` flag, each value type now has its own command. This makes your intent explicit and ensures the right fields are required.

### Major Values (Actionable, Tracked)

Major values are commitments that SHOULD show up in your actions and goals. It should concern you if they don't.

```bash
python interfaces/cli/cli.py values create-major \
  "Value Name" \
  "What this value means to you" \
  --domain Health \
  --priority 85 \
  --guidance "How this shows up in daily/weekly actions"
```

**Required fields:**
- Name (positional)
- Description (positional)
- `--guidance` (How this value manifests in actions/goals)

**Optional fields:**
- `--domain` (default: General)
- `--priority` (default: 5 - highest priority)

### Highest Order Values (Philosophical)

Abstract principles not directly actionable but provide meaning.

```bash
python interfaces/cli/cli.py values create-highest-order \
  "Value Name" \
  "What this principle means" \
  --domain Philosophy \
  --priority 1
```

**Required fields:**
- Name (positional)
- Description (positional)

**Optional fields:**
- `--domain` (default: General)
- `--priority` (default: 1 - highest)

### Life Areas (Organizational, Not Values)

Domains that structure your thinking but aren't evaluative.

```bash
python interfaces/cli/cli.py life-areas create \
  "Area Name" \
  "What this area encompasses" \
  --domain Work \
  --priority 40
```

**Required fields:**
- Name (positional)
- Description (positional)

**Optional fields:**
- `--domain` (default: General)
- `--priority` (default: 40 - mid-range)

### General Values (Aspirational)

Values you affirm but don't necessarily track regularly in goals.

```bash
python interfaces/cli/cli.py values create-general \
  "Value Name" \
  "What this value means" \
  --domain Personal \
  --priority 50
```

**Required fields:**
- Name (positional)
- Description (positional)

**Optional fields:**
- `--domain` (default: General)
- `--priority` (default: 50 - mid-range)

## Example Values (Ready to Use)

Copy and paste these commands, modifying to reflect your actual values.

### Highest Order Values (Core Principles)

These are fundamental guiding principles - the "why" behind everything else.

```bash
# Flourishing - Living Meaningfully
python interfaces/cli/cli.py values create-highest-order \
  "Flourishing" \
  "Living a meaningful, excellent life aligned with truth and growth"

# Truth-Seeking
python interfaces/cli/cli.py values create-highest-order \
  "Truth-Seeking" \
  "Challenge assumptions, prioritize understanding over comfort" \
  --priority 1
```

### Major Values (Actionable + Trackable)

These have clear guidance on how to live them out.

```bash
# Health and Vitality
python interfaces/cli/cli.py values create-major \
  "Health & Vitality" \
  "Physical and mental wellness as foundation for everything" \
  --domain Health \
  --priority 5 \
  --guidance "Exercise 3x/week, 8hrs sleep, nutrition tracking, stress management"

# Technical Mastery
python interfaces/cli/cli.py values create-major \
  "Technical Mastery" \
  "Deep technical skills enabling strategic thinking" \
  --domain Career \
  --priority 10 \
  --guidance "Systematic learning projects, documentation, practical application"

# Community
python interfaces/cli/cli.py values create-major \
  "Community & Service" \
  "Using skills to help organizations grow" \
  --domain Relationships \
  --priority 15 \
  --guidance "Grant work, facilitation, mentor connections, contribution to open source"
```

### Life Areas (Domains to Track)

These represent areas you're developing without implying they're "values."

```bash
# Career Development
python interfaces/cli/cli.py life-areas create \
  "Career Development" \
  "Building toward strategic consulting and C-suite facilitation" \
  --domain Career \
  --priority 30

# Database Skills
python interfaces/cli/cli.py life-areas create \
  "Database & Data Skills" \
  "SQL mastery, pipeline orchestration, data analysis" \
  --domain Career \
  --priority 35

# Personal Systems
python interfaces/cli/cli.py life-areas create \
  "Personal Systems" \
  "ADHD-friendly automation and workflow optimization" \
  --domain Personal \
  --priority 40
```

### General Values (Aspirational)

Values you hold but may not actively pursue in every goal.

```bash
# Continuous Learning
python interfaces/cli/cli.py values create-general \
  "Curiosity & Learning" \
  "Regular pursuit of knowledge and understanding" \
  --domain Personal \
  --priority 65

# Environmental Stewardship
python interfaces/cli/cli.py values create-general \
  "Environmental Care" \
  "Sustainable practices and planet stewardship" \
  --priority 60

# Kindness
python interfaces/cli/cli.py values create-general \
  "Kindness" \
  "Being kind and compassionate to others" \
  --domain Personal \
  --priority 55
```

## Viewing Your Values

```bash
# See all values and life areas
python interfaces/cli/cli.py values list

# Filter by type
python interfaces/cli/cli.py values list --type major
python interfaces/cli/cli.py values list --type life_area

# Filter by domain
python interfaces/cli/cli.py values list --domain Career

# View specific value details
python interfaces/cli/cli.py values show <id>
```

## Expected Output

When you create a value:
```
✓ Created major value: Health & Vitality (ID: 1)
```

When you list values:
```
VALUES
======

ID  Name                    Type            Domain          Priority
1   Health & Vitality       major           Health          5
2   Flourishing             highest_order   Philosophy      1
3   Career Development      life_area       Career          30
4   Kindness                general         Personal        55

Total: 4 values
```

## Editing and Deleting Values

```bash
# Edit a value
python interfaces/cli/cli.py values edit <id> \
  --name "New Name" \
  --description "Updated description" \
  --priority 10 \
  --guidance "New alignment guidance"  # Only for major values

# Delete a value
python interfaces/cli/cli.py values delete <id>

# Force delete (skip confirmation)
python interfaces/cli/cli.py values delete <id> --force
```

## Priority Guidance

Use this scale for priority levels (1 = highest):

- **1-10**: Highest order and top major values (core commitments)
- **11-30**: Important major values actively pursued
- **31-50**: Life areas and strong general values
- **51-70**: Moderate priority general values
- **71-100**: Lower priority aspirational values

**Note:** Lower numbers = higher priority (think "first place")

## Web API Usage

You can also manage values via the web API:

```bash
# Create major value
curl -X POST http://localhost:5000/api/values/major \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Health",
    "description": "Physical wellbeing",
    "priority": 5,
    "alignment_guidance": "Exercise 3x/week"
  }'

# List all values
curl http://localhost:5000/api/values

# Filter by type
curl http://localhost:5000/api/values?type=major

# Get specific value
curl http://localhost:5000/api/values/1

# Update value
curl -X PATCH http://localhost:5000/api/values/1 \
  -H "Content-Type: application/json" \
  -d '{"priority": 10}'

# Delete value
curl -X DELETE http://localhost:5000/api/values/1
```

## Architecture Notes

### Why Type-Specific Commands?

**Before (Confused):**
```bash
python cli.py values create --type major --alignment-guidance "..."
# Type is just a flag, easy to forget what each type needs
```

**After (Explicit):**
```bash
python cli.py values create-major "Name" "Desc" --guidance "..."
# Command itself tells you what kind of value you're creating
```

This is the same reason we have separate commands for actions vs goals - they're conceptually different things that deserve different interfaces.

### Values vs Life Areas

From [categoriae/values.py](../categoriae/values.py):
> "Importantly, LifeAreas are not values"

**Life Areas** help explain why goals matter without evaluative judgment. Your career might guide decisions without you "valuing" it as a core principle. This distinction matters for:
- Goal-Value alignment (future feature)
- Understanding motivation vs commitment
- Avoiding false self-reporting ("I should value my career...")

### Entity Self-Identification

Each entity knows its own type via the `incentive_type` class attribute:
- `MajorValues.incentive_type = 'major'`
- `HighestOrderValues.incentive_type = 'highest_order'`
- `LifeAreas.incentive_type = 'life_area'`
- `Values.incentive_type = 'general'`

This eliminates repetitive type checking throughout the codebase.

## Tips for Your Values

1. **Start with 1-2 Major Values**: Don't over-commit. These should show up regularly in your actions.
2. **Be Concrete with Guidance**: "Exercise 3x/week" > "Be healthy"
3. **Use Life Areas for Organization**: Not everything needs to be a "value"
4. **Distinguish Philosophy from Action**: Highest order values inspire, major values require tracking
5. **Review Quarterly**: Values evolve as you grow

## Alignment with Your Context

Based on your [CLAUDE.md](../CLAUDE.md) profile:

- **Truth-seeking approach**: Highest order value, not a major value (too abstract for daily tracking)
- **Systematic analysis**: Shows up as guidance in major values
- **Career goals**: Mix of major values (mastery) and life areas (domains to develop)
- **ADHD support**: Clear, specific guidance in major values
- **Incremental building**: Reflected in how values connect to goals

## Future Features

- **Goal-Value Alignment Inference**: Automatically detect which goals serve which values
- **Value Coverage Dashboard**: See which values are/aren't being served by current goals
- **Priority Conflict Detection**: Warn if life areas have higher priority than major values
- **Timeline View**: Track how value priorities shift over time

## Questions?

See the main [CLAUDE.md](../CLAUDE.md) for:
- Full architecture details
- Layer responsibilities (categoriae/rhetorica/ethica/politica/interfaces)
- Testing workflow
- Database schema

---

**Last Updated:** 2025-10-13
**Architecture:** Type-specific endpoints, orchestration service, entity self-identification
