# Ten Week Goal App - Development Roadmap

**Created:** 2025-10-12
**Purpose:** Guide systematic development without skipping foundational layers
**Principle:** Only build interfaces when backend (categoriae → ethica → rhetorica → politica) is mature

---

## Table of Contents

1. [Current State Assessment](#current-state-assessment)
2. [Architectural Clarity: Relationships](#architectural-clarity-relationships)
3. [Development Phases](#development-phases)
4. [Maturity Criteria](#maturity-criteria)
5. [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## Current State Assessment

### ✅ Fully Mature (Ready for Interfaces)

| Feature | categoriae | ethica | rhetorica | politica | Tests | Status |
|---------|-----------|--------|-----------|----------|-------|--------|
| **Progress Viewing** | ✅ Goal, Action | ✅ aggregation | ✅ storage | ✅ tables | ✅ 48/48 | **CLI + Web exist** |
| **Values System** | ✅ hierarchy | ✅ validation | ✅ storage | ✅ table | ✅ 16 tests | **Ready to expose** |
| **Action-Goal Inference** | ✅ relationships | ✅ matching | ✅ storage | ✅ table | ✅ 7 tests | **Ready to expose** |

### ⚠️ Partially Mature (Needs Work)

| Feature | What Exists | What's Missing |
|---------|------------|----------------|
| **Action CRUD** | Domain + Storage | ethica validation, interfaces |
| **Goal CRUD** | Domain + Storage | Interfaces only |
| **Goal-Value Alignment** | Domain model | ethica inference logic, storage |
| **Terms** | Domain + calculations | Storage, tests, interfaces |

### 📝 Concept Only (Not Designed)

| Feature | Status |
|---------|--------|
| **Action-Value relationships** | No domain model, no logic |
| **Term-based planning** | Domain exists, workflow undefined |
| **Bulk import/export** | No implementation |

---

## Architectural Clarity: Relationships

### Three Distinct Relationship Types

```
┌────────────────────────────────────────────────┐
│  ACTION → GOAL Relationship                    │
│  - Status: MATURE                              │
│  - Inference: progress_matching.py (ethica)    │
│  - Storage: ActionGoalProgressStorageService   │
│  - Table: action_goal_progress                 │
│  - Use case: "Does this action contribute?"    │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  GOAL → VALUE Relationship                     │
│  - Status: PARTIAL                             │
│  - Inference: MISSING (needs value_alignment.py)│
│  - Storage: MISSING                            │
│  - Table: MISSING                              │
│  - Use case: "Does this goal serve my values?" │
└────────────────────────────────────────────────┘

┌────────────────────────────────────────────────┐
│  ACTION → VALUE Relationship                   │
│  - Status: CONCEPT ONLY                        │
│  - Inference: UNDEFINED                        │
│  - Design question: Emergent from Action→Goal→Value?│
│  - Use case: "Am I living my values?"          │
└────────────────────────────────────────────────┘
```

### Key Distinction: Inference vs Assignment

**Inference** (Computing suggested relationships):
- Layer: **ethica/** (business logic)
- Process: Algorithm analyzes entities and suggests matches
- Output: `List[DerivedRelationship]` with confidence scores
- State: Transient (can be recalculated anytime)
- Examples: `infer_matches()`, `infer_value_alignment()` (future)

**Assignment** (Managing confirmed relationships):
- Layer: **rhetorica/politica** (storage)
- Process: User reviews inference suggestions and confirms/rejects
- Output: Persistent relationships with `assignment_method` field
- State: Durable (stored in database)
- Methods:
  - `auto_inferred` → Algorithm suggested
  - `user_confirmed` → User approved suggestion
  - `manual` → User explicitly created

**Review UI** bridges inference and assignment:
1. Run inference → Get suggestions
2. Present to user → Review interface
3. User confirms/rejects → Store assignments
4. Stored assignments supersede future inference

---

## Development Phases

### Phase 1: Values Foundation (Expose What Exists)

**Goal:** Enable value-aware planning by exposing fully mature values system

**Rationale:**
- Domain entities complete and tested (16 tests)
- Storage service works with polymorphic types
- Critical for your use case: "consider actions/goals in context of values"

**Tasks:**

#### 1.1 CLI Interface
```bash
# Value management commands
cli.py values list                          # List all values
cli.py values list --type major            # Filter by type
cli.py values list --area Health           # Filter by life area
cli.py values show --id 5                  # Detail view
cli.py values create --name "Health" \
              --description "..." \
              --type major \
              --area Health \
              --priority 10
cli.py values edit --id 5 --priority 5
cli.py values delete --id 5
```

**Files to create:**
- `interfaces/cli.py` - Add `values` subcommand
- Update formatters for value display

#### 1.2 Web Interface
```
/values                  # Values dashboard
/values/<id>            # Value detail view
/value/new              # Create form
/value/<id>/edit        # Edit form
```

**Files to create:**
- `interfaces/web_app.py` - Add routes
- `interfaces/templates/values.html`
- `interfaces/templates/value_detail.html`
- `interfaces/templates/value_form.html`

#### 1.3 API Endpoints
```
GET  /api/values              # List with filters
GET  /api/values/<id>         # Detail
POST /api/values              # Create
PUT  /api/values/<id>         # Update
DELETE /api/values/<id>       # Delete
```

**Completion Criteria:**
- [ ] Can list all values with hierarchy types
- [ ] Can filter by life area and priority
- [ ] Can create/edit/delete values through all interfaces
- [ ] Polymorphic storage works (MajorValue retrieves as MajorValue)

---

### Phase 2: Action Management (Build Missing Layers)

**Goal:** Enable daily action tracking with validation and interfaces

**Current State:**
- ✅ categoriae: `Action` class complete
- ✅ politica: CRUD operations exist
- ✅ rhetorica: `ActionStorageService` exists
- ❌ ethica: No validation rules defined
- ❌ interfaces: No CRUD operations

**Build Order:**

#### 2.1 Business Logic Layer (ethica)

Create `ethica/action_validation.py`:
```python
"""
Action validation rules - what makes a valid action?

Business rules:
- Description required and non-empty
- Measurements must be positive numbers
- If start_time provided, duration_minutes required
- logtime cannot be in future
- Measurement keys must be valid units
"""

def validate_action(action: Action) -> ValidationResult:
    """Validate action against business rules."""

def validate_measurement_keys(measurements: dict) -> bool:
    """Check measurement keys are recognized units."""

def suggest_measurement_keys(description: str) -> List[str]:
    """Suggest measurement keys based on description."""
```

**Why this matters:**
- Prevents invalid data entry
- Enforces business rules consistently
- Provides helpful feedback to user

#### 2.2 Storage Conveniences (rhetorica)

`ActionStorageService` exists but could add:
```python
def get_by_date_range(start: date, end: date) -> List[Action]:
    """Fetch actions in date range."""

def get_by_measurement_type(unit: str) -> List[Action]:
    """Fetch actions with specific measurement type."""

def search_descriptions(query: str) -> List[Action]:
    """Full-text search on descriptions."""
```

#### 2.3 Interfaces (CLI + Web + API)

**CLI:**
```bash
cli.py action add "Ran 5km" --km 5.0 --date 2025-10-12
cli.py action list --from 2025-10-01 --to 2025-10-31
cli.py action list --unit km
cli.py action edit 123 --description "Ran 5.5km" --km 5.5
cli.py action delete 123
cli.py action search "yoga"
```

**Web:**
```
/actions                      # List with filters
/action/new                   # Create form
/action/<id>/edit             # Edit form
/action/<id>/delete           # Delete confirmation
```

**API:**
```
GET  /api/actions?from=...&to=...&unit=...
POST /api/actions
PUT  /api/actions/<id>
DELETE /api/actions/<id>
```

**Completion Criteria:**
- [ ] Validation rules prevent invalid actions
- [ ] Can create actions through all interfaces
- [ ] Can filter/search actions effectively
- [ ] Can edit/delete actions safely

---

### Phase 3: Values Implementation (Your Personal Values)

**Goal:** Populate system with your actual values using interfaces from Phase 1

**Prerequisites:**
- Phase 1 complete (values interfaces working)

**Tasks:**

#### 3.1 Define Your Values Hierarchy

Document in `.documentation/personal_values.md`:
```markdown
# My Personal Values

## Highest Order Values (Ultimate purposes)
1. **Growth & Development** (Priority: 1)
   - Life area: Personal Development
   - Why: Continuous improvement is fulfillment

## Major Values (Important life domains)
1. **Health & Vitality** (Priority: 5)
   - Life area: Health
   - Serves: Growth & Development

2. **Meaningful Work** (Priority: 8)
   - Life area: Career
   - Serves: Growth & Development

## Values (Specific motivators)
...
```

#### 3.2 Enter Values Through UI

Use Phase 1 web interface or CLI to enter:
- Highest order values (~2-3)
- Major values (~5-8)
- Regular values (~10-15)

#### 3.3 Verify Storage

Test polymorphic retrieval:
```python
values_service = ValuesStorageService()
all_values = values_service.get_all()

# Should retrieve correct types
for v in all_values:
    assert type(v).__name__ == v.type_name  # Polymorphism working
```

**Completion Criteria:**
- [ ] Personal values documented
- [ ] Values entered through UI
- [ ] Polymorphic storage verified
- [ ] Can view values in all interfaces

---

### Phase 4: Relationship Management Architecture

**Goal:** Clarify and implement relationship lifecycle systematically

#### 4.1 Architectural Clarification

**The Relationship Lifecycle:**
```
1. INFERENCE (ethica)
   ↓ Algorithm suggests relationships

2. REVIEW (interfaces)
   ↓ User sees suggestions

3. ASSIGNMENT (rhetorica/politica)
   ↓ User confirms/rejects

4. STORAGE (politica)
   ↓ Confirmed relationships persist

5. USAGE (all layers)
   ↓ Stored relationships used in analysis
```

#### 4.2 Action-Goal Relationships (Already Mature)

**What exists:**
- ✅ Inference: `ethica/progress_matching.py` with actionability
- ✅ Storage: `rhetorica/progress_storage.py`
- ✅ Table: `action_goal_progress`
- ✅ Tests: `test_actionability_matching.py`

**What's missing:**
- ❌ Review UI for ambiguous matches
- ❌ Manual match creation UI
- ❌ Confirmation workflow

**Build:**

Create `interfaces/cli.py` additions:
```bash
# Review inference suggestions
cli.py inference run --from 2025-04-01 --to 2025-06-21
cli.py inference review              # Show pending suggestions
cli.py inference show --match-id 45  # Detail view
cli.py inference confirm 45          # Accept suggestion
cli.py inference reject 46           # Reject suggestion

# Manual relationship management
cli.py match create --action 123 --goal 5 --contribution 5.0
cli.py match list --goal 5
cli.py match delete --action 123 --goal 5
```

Web interface:
```
/inference/review                    # Review dashboard
/inference/match/<id>               # Detail + confirm/reject
/goal/<id>/matches                  # Manage matches for goal
```

#### 4.3 Goal-Value Alignment (Needs Building)

**Current state:**
- ✅ Domain: `GoalValueAlignment` class exists
- ❌ Inference: No `ethica/value_alignment.py`
- ❌ Storage: No service or table
- ❌ Tests: None

**Build Order:**

**Step 1: Design inference logic**

Create `ethica/value_alignment.py`:
```python
"""
Goal-Value alignment inference.

Detects which goals serve which values based on:
- Life area matching (goal.life_area == value.life_area)
- Keyword overlap (goal description contains value keywords)
- Explicit alignment_guidance in value
"""

def infer_value_alignments(
    goals: List[Goal],
    values: List[MajorValue]
) -> List[GoalValueAlignment]:
    """
    Suggest which goals align with which values.

    Algorithm:
    1. Match by life area (Health goal → Health value)
    2. Check alignment_guidance keywords
    3. Score alignment strength (0.0-1.0)
    4. Return suggestions above threshold
    """
```

**Step 2: Create storage**

Schema `politica/schemas/goal_value_alignment.sql`:
```sql
CREATE TABLE goal_value_alignment (
  id INTEGER PRIMARY KEY,
  goal_id INTEGER NOT NULL,
  value_id INTEGER NOT NULL,
  alignment_strength REAL NOT NULL,
  assignment_method TEXT NOT NULL,
  confidence REAL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (goal_id) REFERENCES goals(id),
  FOREIGN KEY (value_id) REFERENCES values(id),
  UNIQUE(goal_id, value_id)
);
```

Service `rhetorica/value_alignment_storage.py`:
```python
class GoalValueAlignmentStorageService:
    """Manage goal-value relationship persistence."""

    def store_alignments(self, alignments: List[GoalValueAlignment])
    def get_by_goal(self, goal_id: int)
    def get_by_value(self, value_id: int)
    def create_manual_alignment(...)
    def confirm_suggestion(...)
```

**Step 3: Build interfaces**

CLI:
```bash
cli.py alignment infer              # Run inference
cli.py alignment review             # Review suggestions
cli.py alignment confirm 78
cli.py goal show --id 5 --with-values  # Show goal's values
cli.py value show --id 3 --with-goals  # Show value's goals
```

Web:
```
/alignment/review                   # Review suggested alignments
/goal/<id>/values                  # Manage goal's values
/value/<id>/goals                  # Manage value's goals
```

**Completion Criteria:**
- [ ] Can infer goal-value alignments
- [ ] Can review and confirm suggestions
- [ ] Can manually create alignments
- [ ] Can view goals by value
- [ ] Can answer: "Which values are my goals serving?"

#### 4.4 Action-Value Relationships (Design Decision Needed)

**Question:** Are Action-Value relationships:
- **Emergent** from Action→Goal→Value chain?
- **Direct** (actions can reflect values without goal)?

**Option A: Emergent (Recommended)**
```python
def get_action_values(action: Action) -> List[Tuple[Value, float]]:
    """
    Get values an action serves (transitively).

    Algorithm:
    1. Find goals this action contributes to
    2. Find values those goals align with
    3. Compute transitive alignment strength
    """
    action_goals = get_action_goals(action)
    values = []
    for goal, contribution in action_goals:
        goal_values = get_goal_values(goal)
        for value, alignment in goal_values:
            strength = contribution * alignment
            values.append((value, strength))
    return aggregate(values)
```

**Benefits:**
- No new relationship type needed
- Reflects actual planning structure (set goals → track actions)
- Simpler to reason about

**Option B: Direct**
- Add `ActionValueReflection` relationship
- Inference logic for direct value expression
- Use case: Actions that reflect values without specific goal

**Decision deferred until Phase 4 implementation**

---

### Phase 5: Terms & Time Horizons

**Goal:** Enable term-based planning and value neglect analysis

**Current State:**
- ✅ categoriae: `TenWeekTerm`, `YearlyPlan`, `LifeTime` complete
- ✅ categoriae: Calculation methods work
- ❌ Storage: No `TermStorageService`
- ❌ Table: No `terms` schema
- ❌ Tests: No `test_terms.py`
- ❌ Integration: Goals not linked to terms

**Build Order:**

#### 5.1 Storage Layer

**Schema** `politica/schemas/terms.sql`:
```sql
CREATE TABLE terms (
  id INTEGER PRIMARY KEY,
  term_number INTEGER NOT NULL,
  start_date TEXT NOT NULL,
  end_date TEXT NOT NULL,
  theme TEXT,
  reflection TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(term_number)
);

-- Link goals to terms
ALTER TABLE goals ADD COLUMN term_id INTEGER REFERENCES terms(id);
```

**Service** `rhetorica/term_storage.py`:
```python
class TermStorageService(StorageService[TenWeekTerm]):
    """Manage term persistence."""

    def get_current_term(self) -> Optional[TenWeekTerm]
    def get_by_year(self, year: int) -> List[TenWeekTerm]
    def get_active_goals(self, term_id: int) -> List[Goal]
```

#### 5.2 Business Logic

**Term Analysis** `ethica/term_analysis.py`:
```python
"""
Term-based analysis - which values were prioritized/neglected?

Answers questions:
- Which values did I focus on this term?
- Which values were neglected?
- How balanced was my term across life areas?
"""

def analyze_term_value_focus(
    term: TenWeekTerm,
    goals: List[Goal],
    values: List[MajorValue],
    alignments: List[GoalValueAlignment]
) -> TermValueReport:
    """
    Analyze which values were emphasized this term.

    Returns:
    - values_served: List[(value, goal_count, action_count)]
    - values_neglected: List[value]
    - balance_score: 0.0-1.0 (how balanced across life areas)
    - recommendations: List[str] for next term
    """
```

#### 5.3 Planning Workflow

**Use case:** "Set goals for next term with awareness of neglected values"

Workflow:
```bash
# 1. Review current term
cli.py term review --current
# Shows: Which values served, which neglected

# 2. Plan next term
cli.py term plan --next
# Suggests: Focus on neglected values

# 3. Create goals
cli.py goal create --term-id 2 --aligned-with "Health" ...

# 4. Start tracking
cli.py action add "Morning run" --km 5.0
```

#### 5.4 Interfaces

CLI:
```bash
cli.py term list
cli.py term current
cli.py term review --id 1               # Analysis + reflection
cli.py term plan --next                 # Planning aid
cli.py term create --start 2025-04-12 --theme "Health & Learning"
```

Web:
```
/terms                          # Term timeline
/term/<id>                      # Term dashboard
/term/<id>/review              # Value analysis
/term/new                       # Planning wizard
```

**Completion Criteria:**
- [ ] Can create and manage terms
- [ ] Goals link to terms
- [ ] Can analyze value focus per term
- [ ] Can identify neglected values
- [ ] Planning workflow supports value awareness

---

### Phase 6: Goal-Value Alignment Analysis

**Goal:** Answer "Which values have been ignored?" systematically

**Prerequisites:**
- Phase 4 complete (Goal-Value alignments work)
- Phase 5 complete (Terms work)

**Capabilities to Build:**

#### 6.1 Value Neglect Detection

`ethica/value_analysis.py`:
```python
def detect_neglected_values(
    values: List[MajorValue],
    alignments: List[GoalValueAlignment],
    progress: List[GoalProgress],
    time_period: Optional[TenWeekTerm] = None
) -> ValueNeglectReport:
    """
    Identify which values lack goal/action support.

    Algorithm:
    1. For each value, count aligned goals
    2. For aligned goals, check progress
    3. Flag values with:
       - No aligned goals
       - Aligned goals with no progress
       - Aligned goals below 25% progress
    4. Weight by value priority
    """
```

#### 6.2 Dashboard Views

**Values Dashboard:**
```
/values/health-check                # Value health overview

For each major value:
├─ Aligned goals: 3
├─ Active goals: 2
├─ Progress: 45% avg
├─ Actions this term: 23
└─ Status: ACTIVE / NEGLECTED / OVEREMPHASIZED
```

**Term Planning:**
```
/term/plan?term=2                  # Next term planning

Values needing attention:
├─ Health (last addressed: 3 terms ago)
├─ Relationships (only 10% progress current term)
└─ Learning (no aligned goals)

Suggested goals:
├─ Health goal: "Exercise 3x/week"
└─ Relationship goal: "Weekly social activities"
```

**Completion Criteria:**
- [ ] Can identify neglected values
- [ ] Can see value health across terms
- [ ] Planning workflow highlights neglected values
- [ ] Can answer: "Am I living according to my values?"

---

## Maturity Criteria

A feature is **ready for interface layer** when:

### 1. Domain Model (categoriae)
- [ ] Entity classes defined
- [ ] Validation methods implemented
- [ ] Relationships to other entities clear

### 2. Business Logic (ethica)
- [ ] Core algorithms implemented
- [ ] Stateless functions (input → output)
- [ ] Edge cases handled
- [ ] Documentation explains "why"

### 3. Storage (rhetorica + politica)
- [ ] StorageService implemented
- [ ] Database schema created
- [ ] CRUD operations work
- [ ] Type preservation (polymorphism)

### 4. Tests
- [ ] >80% code coverage
- [ ] Edge cases tested
- [ ] Integration tests pass
- [ ] No skipped/ignored tests

### 5. Documentation
- [ ] Docstrings complete
- [ ] Architecture decisions documented
- [ ] Usage examples provided

**Only when all 5 criteria met** should interfaces be built.

---

## Anti-Patterns to Avoid

### ❌ Skipping ethica Layer

**Wrong:**
```python
# Putting business logic in interface
@app.route('/action/validate')
def validate_action():
    if not action.description:
        return error("Description required")  # Business rule in interface!
```

**Right:**
```python
# Business logic in ethica
from ethica.action_validation import validate_action

@app.route('/action/validate')
def validate_action_endpoint():
    result = validate_action(action)  # ethica handles rules
    return jsonify(result)
```

### ❌ Building UI Before Backend

**Wrong:**
```python
# Building forms before storage works
@app.route('/term/new')
def create_term_form():
    # No TermStorageService exists yet!
    return render_template('term_form.html')
```

**Right:**
1. Build TermStorageService
2. Write tests
3. Verify storage works
4. **Then** build form

### ❌ Conflating Inference and Assignment

**Wrong:**
```python
# Storing inference results directly
matches = infer_matches(actions, goals)
for match in matches:
    db.insert('action_goal_progress', match)  # No review step!
```

**Right:**
```python
# Inference suggests, user confirms, then store
suggestions = infer_matches(actions, goals)  # Transient
reviewed = user_reviews(suggestions)         # UI step
confirmed = filter(reviewed, accepted=True)
storage_service.store_relationships(confirmed)  # Persistent
```

### ❌ Premature Optimization

**Wrong:**
```python
# Building complex caching before it's needed
class CachedInferenceService:
    def infer_with_redis_cache(...)  # Complexity before necessity
```

**Right:**
```python
# Simple first, optimize later
def infer_matches(...):
    # Straightforward implementation
    # Profile first, optimize second
```

---

## Success Metrics

### Short Term (1-2 months)
- [ ] Can enter and view personal values through UI
- [ ] Can create and track daily actions
- [ ] Can review and confirm action-goal matches
- [ ] Can see which values current goals serve

### Medium Term (3-4 months)
- [ ] Can plan terms with value-awareness
- [ ] Can identify neglected values per term
- [ ] Can create goals aligned with values
- [ ] Term-based progress reports work

### Long Term (5-6 months)
- [ ] Complete workflow: values → terms → goals → actions
- [ ] Analytical insights: "Am I living my values?"
- [ ] Historical analysis: Value focus over multiple terms
- [ ] System guides planning toward balance

---

## Revision History

| Date | Changes | Reason |
|------|---------|--------|
| 2025-10-12 | Initial roadmap | Align on systematic development |

---

## Next Steps

1. **Review this roadmap** - Verify alignment with your vision
2. **Choose starting phase** - Likely Phase 1 (Values) or Phase 2 (Actions)
3. **Begin systematic build** - Follow maturity criteria
4. **Document as you go** - Capture decisions and rationale

**Remember:** The goal is systematic development where each layer is solid before building on top of it. Interfaces are the **last** step, not the first.
