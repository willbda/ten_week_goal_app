# JavaScript Implementation Exploration Report
## Ten Week Goal App - Multi-Language Architecture Analysis

**Date:** October 23, 2025
**Scope:** Python, Swift, and Shared Database Analysis for JavaScript Port

---

## Executive Summary

The Ten Week Goal App is a sophisticated personal goal tracking system built on clean architecture principles with strict separation of concerns. It currently has fully-functional Python (90+ tests, 25 CLI commands, 27 API endpoints) and Swift implementations (281 tests, active development) that maintain identical business logic while leveraging language-specific patterns.

**Key Finding:** Both implementations share the same SQLite database schema and domain models. A JavaScript port would benefit from understanding how each language handles:
1. **Domain Model Polymorphism** (Goal/Milestone/SmartGoal hierarchy)
2. **Relationship Inference** (matching actions to goals via business logic)
3. **Type-Safe Database Operations** (Python dicts → Swift protocols → JavaScript ?)
4. **Layered Architecture** (categoriae → ethica → politica → rhetorica)

---

## Part 1: Overall Project Organization

### Directory Structure

```
ten_week_goal_app/
├── python/                    # ✅ Fully functional reference implementation
│   ├── categoriae/           # Domain entities (9 classes + protocols)
│   ├── ethica/               # Business logic (4 modules, 90+ tests)
│   ├── rhetorica/            # Translation layer (2 storage modules)
│   ├── politica/             # Infrastructure (single database module)
│   ├── config/               # Configuration and logging
│   ├── interfaces/
│   │   └── flask/            # 27 API endpoints + Web UI
│   └── tests/                # 90 passing tests
│
├── swift/                     # 🚧 Active development
│   ├── Sources/
│   │   ├── Models/           # Domain entities (8 protocols + 5 structs)
│   │   ├── Database/         # GRDB integration (3 files)
│   │   ├── BusinessLogic/    # Matching & inference services
│   │   └── App/              # SwiftUI views (prototype)
│   └── Tests/                # 281 passing tests
│
└── shared/                    # 📋 Shared database schemas
    └── schemas/              # 8 .sql files (both languages read these)
```

### Shared Resources

**Database Schemas** (`shared/schemas/*.sql`):
- `actions.sql` - Action tracking table
- `goals.sql` - Goal storage (supports polymorphism via `goal_type`)
- `values.sql` - Personal values hierarchy
- `terms.sql` - 10-week time periods
- `action_goal_progress.sql` - Relationship cache/projections
- `archive.sql` - Audit trail for all changes
- `expectations.sql` - (unused currently)
- `uuid_mappings.sql` - Swift UUID↔Python INTEGER mapping (legacy)

**Key Fact:** Both Python and Swift read from the same database schema directory. A JavaScript implementation would do the same.

---

## Part 2: Python Implementation Architecture

### Layer 1: Domain Entities (`categoriae/`)

**Philosophy:** "What things ARE" - pure domain models with zero infrastructure dependencies

#### Key Classes

**Action** (actions.py)
```python
@dataclass
class Action(PersistableEntity):
    """An action taken at a point in time"""
    measurement_units_by_amount: Optional[Dict[str, float]] = None  # e.g., {"km": 5.0}
    duration_minutes: Optional[float] = None
    start_time: Optional[datetime] = None
    
    def is_valid(self) -> bool:
        """Validate action structure"""
```

**Goal Hierarchy** (goals.py)
```python
@dataclass
class ThingIWant(PersistableEntity):
    """Parent - all things have description"""
    pass

@dataclass(unsafe_hash=True)
class Goal(ThingIWant):
    """Flexible objective with optional measurements/dates"""
    goal_type: str = 'Goal'
    measurement_unit: Optional[str] = None
    measurement_target: Optional[float] = None
    start_date: Optional[datetime] = None
    target_date: Optional[datetime] = None
    # ... SMART criterion fields

@dataclass
class Milestone(Goal):
    """Point-in-time checkpoint"""
    goal_type: str = 'Milestone'
    # Validates: target_date required, start_date cleared

@dataclass
class SmartGoal(Goal):
    """Fully SMART-compliant goal with strict validation"""
    goal_type: str = 'SmartGoal'
    # Validates: all fields required, dates valid
```

**Values Hierarchy** (values.py)
```python
@dataclass
class Incentives(PersistableEntity):
    """Base for values/life-areas"""
    priority: PriorityLevel = 50      # 1-100
    life_domain: str = "General"
    incentive_type: str = 'incentive'

@dataclass
class Values(Incentives):
    """Personal values"""
    incentive_type: str = 'general'

@dataclass
class MajorValues(Values):
    """Actionable values requiring tracking"""
    incentive_type: str = 'major'
    alignment_guidance: Optional[str] = None

@dataclass
class HighestOrderValues(Values):
    """Abstract philosophical values"""
    incentive_type: str = 'highest_order'
```

**Base Entities** (ontology.py)
```python
@dataclass
class PersistableEntity(IndependentEntity):
    """All storable entities inherit this"""
    log_time: datetime = field(default_factory=datetime.now)
    uuid_id: UUID = field(default_factory=uuid4, kw_only=True)
    id: Optional[int] = field(default=None, kw_only=True)  # Python INTEGER ID
    description: Optional[str] = None
    notes: Optional[str] = None

@dataclass
class DerivedEntity:
    """Base for computed relationships (not source of truth)"""
    pass
```

**Relationships** (relationships.py)
```python
@dataclass
class ActionGoalRelationship(DerivedEntity):
    """Links action → goal with confidence score"""
    action: Action
    goal: Goal
    contribution: float                    # Amount contributed (e.g., 5.0 km)
    assignment_method: str                 # 'auto_inferred', 'user_confirmed', 'manual'
    confidence: float = 1.0               # 0.0-1.0

@dataclass
class MajorValueAlignment(DerivedEntity):
    """Links goal → value"""
    goal: Goal
    value: MajorValues
    alignment_strength: float
    assignment_method: str
    confidence: float = 1.0
```

### Layer 2: Business Logic (`ethica/`)

**Philosophy:** "What SHOULD happen" - stateless functions implementing domain rules

#### Key Modules

**Progress Aggregation** (progress_aggregation.py)
```python
@dataclass
class GoalProgress:
    """Aggregated metrics for a goal"""
    goal: Goal
    matches: List[ActionGoalRelationship]
    total_progress: float
    target: float
    
    @property
    def percent(self) -> float:
        """0.0 to >100.0"""
        return (self.total_progress / self.target) * 100 if self.target > 0 else 0
    
    @property
    def remaining(self) -> float:
        return max(0.0, self.target - self.total_progress)
    
    @property
    def is_complete(self) -> bool:
        return self.total_progress >= self.target

def aggregate_goal_progress(goal: Goal, matches: List[ActionGoalRelationship]) -> GoalProgress:
    """AUTHORITATIVE progress calculation"""
    total = sum(m.contribution for m in matches if m.contribution)
    return GoalProgress(goal=goal, matches=matches, total_progress=total, target=...)

def aggregate_all_goals(goals: List[Goal], all_matches: List[ActionGoalRelationship]) -> List[GoalProgress]:
    """Batch progress calculation"""
```

**Progress Matching** (progress_matching.py)
```python
def matches_on_period(action: Action, goal: Goal) -> bool:
    """Check if action occurred during goal's timeframe"""
    
def matches_on_unit(action: Action, goal: Goal) -> Tuple[bool, Optional[str], Optional[float]]:
    """Check if action measurement matches goal unit"""
    
def matches_with_how_goal_is_actionable(action: Action, goal: Goal) -> Tuple[bool, Optional[float]]:
    """Structured keyword + unit matching"""
    
def infer_matches(actions: List[Action], goals: List[Goal], require_period_match=True) -> List[ActionGoalRelationship]:
    """Batch inference - returns ALL possible matches"""
    
def filter_ambiguous_matches(matches: List[ActionGoalRelationship], confidence_threshold=0.7) -> Tuple[List, List]:
    """Separate high-confidence from ambiguous matches"""
```

**Inference Service** (inference_service.py)
```python
class ActionGoalInferenceService:
    """Orchestrates matching operations"""
    
    def __init__(self, action_service, goal_service, progress_service=None):
        self.action_service = action_service
        self.goal_service = goal_service
    
    def infer_for_period(self, start_date, target_date, confidence_threshold=0.7) -> InferenceSession:
        """Batch inference for time period"""
        
    def infer_for_action(self, action: Action) -> List[ActionGoalRelationship]:
        """Realtime matching for single action"""
```

**Key Pattern:** All ethica functions are pure (no side effects), stateless, and fully testable without a database.

### Layer 3: Translation Layer (`rhetorica/`)

**Philosophy:** "Translation between domains" - bridges domain entities ↔ storage dicts

#### Storage Service Pattern

```python
class StorageService(ABC, Generic[T]):
    """Base for all storage services"""
    table_name: str = ''
    entity_class: Optional[Type[T]] = None
    
    def __init__(self, database: Optional[Database] = None):
        self.db = database or Database()
    
    def store_single_instance(self, entry: T) -> T:
        """Save entity, populate ID"""
        entity_dict = self._to_dict(entry)
        db_id = self.db.insert(self.table_name, [entity_dict])[0]
        entry.id = db_id
        return entry
    
    def get_all(self, filters: Optional[dict] = None) -> List[T]:
        """Fetch all entities"""
        records = self.db.query(self.table_name, filters=filters)
        return [self._from_dict(record) for record in records]
    
    def save(self, entity: T) -> T:
        """Smart save: insert if new, update if exists"""
        if entity.id is None:
            return self.store_single_instance(entity)
        else:
            return self.update_instance(entity)
    
    def _to_dict(self, entity: T) -> dict:
        """Entity → storage dict (override in subclass)"""
        raise NotImplementedError
    
    def _from_dict(self, data: dict) -> T:
        """storage dict → Entity (override in subclass)"""
        raise NotImplementedError
```

#### Polymorphic Goal Storage Example

```python
class GoalStorageService(StorageService[Goal]):
    """Handles Goal, Milestone, SmartGoal polymorphism"""
    table_name = 'goals'
    entity_class = Goal
    
    CLASS_MAP = {
        'Goal': Goal,
        'Milestone': Milestone,
        'SmartGoal': SmartGoal
    }
    
    def _to_dict(self, goal: Goal) -> dict:
        return {
            'uuid_id': str(goal.uuid_id),
            'title': goal.title,
            'goal_type': goal.goal_type,  # ← Type identifier
            'measurement_target': goal.measurement_target,
            # ... all fields
        }
    
    def _from_dict(self, data: dict) -> Goal:
        """Reconstruct correct subclass based on goal_type"""
        goal_type = data.get('goal_type', 'Goal')
        goal_class = self.CLASS_MAP.get(goal_type, Goal)
        
        return goal_class(
            uuid_id=UUID(data['uuid_id']),
            title=data['title'],
            # ... initialize from dict
        )
```

**Key Pattern:** Storage services translate from domain objects to primitive dicts/lists that politica understands.

### Layer 4: Infrastructure (`politica/`)

**Philosophy:** "How it's DONE" - raw SQLite operations with ZERO knowledge of domain entities

#### Database Operations

```python
class Database:
    """Pure SQLite interface"""
    
    def __init__(self, db_path: Path, schema_path: Path):
        self.db_path = db_path
        self.schema_path = schema_path
    
    def query(self, table: str, filters: Optional[dict] = None) -> List[dict]:
        """SELECT - returns List[dict] only"""
        
    def insert(self, table: str, records: List[dict]) -> List[int]:
        """INSERT - returns list of inserted IDs"""
        
    def update(self, table: str, entity_id: int, updates: dict, notes: str = '') -> None:
        """UPDATE - archives old version before updating"""
        
    def archive_and_delete(self, table: str, filters: dict, reason: str, notes: str = '') -> None:
        """DELETE - archives records first"""
    
    @staticmethod
    def build_where_clause(filters: dict) -> Tuple[str, List]:
        """Helper: builds WHERE clause from filters"""
        
    @staticmethod
    def build_set_clause(updates: dict) -> Tuple[str, List]:
        """Helper: builds SET clause from updates"""
```

**Critical Rule:** politica NEVER imports from categoriae or ethica. Only works with:
- Table names (strings)
- Column names (strings)  
- Primitive values (dict[str, Any])

### Layer 5: Interfaces

#### Flask API (`interfaces/flask/`)

```python
# Example: GET /api/goals
@api_bp.route('/goals', methods=['GET'])
def get_goals():
    """List goals with optional filtering"""
    service = GoalStorageService()
    
    # Get from storage (rhetorica)
    goals = service.get_all(type_filter=request.args.get('type'))
    
    # Apply filters
    if request.args.get('has_dates') == 'true':
        goals = [g for g in goals if g.is_time_bound()]
    
    # Serialize for HTTP
    goals_data = [serialize(g, include_type=True) for g in goals]
    
    return jsonify({'goals': goals_data, 'count': len(goals_data)}), 200
```

**Pattern:** 
1. Create storage service (rhetorica)
2. Call service methods (orchestration)
3. Apply business logic if needed (ethica)
4. Serialize and return

#### 25 CLI Commands (not shown in detail, but structured same way)
- 6 Action commands (create, list, show, edit, delete, goals)
- 6 Goal commands (create, list, show, edit, delete, progress)
- 7 Term commands (create, list, show, current, edit, add-goal, remove-goal)
- 5 Value commands (create, list, show, edit, delete)
- 1 Progress dashboard command

---

## Part 3: Swift Implementation Architecture

### Overview

Swift uses the same **layer architecture** as Python but leverages:
- **Swift 6.2 strict concurrency** (actors, async/await, Sendable)
- **GRDB.swift for type-safe database** (Codable, FetchableRecord, PersistableRecord)
- **Protocol-oriented design** instead of inheritance
- **Direct domain↔database mapping** (no separate Record types)

### Layer 1: Domain Models (`Sources/Models/`)

#### Protocol-Oriented Design

```swift
// MARK: - Core Ontology Protocols

public protocol Persistable: Identifiable, Equatable {
    var id: UUID { get set }
    var title: String? { get set }
    var detailedDescription: String? { get set }
    var freeformNotes: String? { get set }
    var logTime: Date { get set }
}

public protocol Completable {
    var targetDate: Date? { get set }
    var measurementUnit: String? { get set }
    var measurementTarget: Double? { get set }
    var startDate: Date? { get set }
}

public protocol Doable {
    var measuresByUnit: [String: Double]? { get set }
    var durationMinutes: Double? { get set }
    var startTime: Date? { get set }
}

public protocol Motivating {
    var priority: Int { get set }
    var lifeDomain: String? { get set }
}

public protocol Validatable {
    func isValid() -> Bool
    func validate() throws
}

public protocol Polymorphable {
    var polymorphicSubtype: String { get }
}
```

#### Action Model with GRDB Integration

```swift
public struct Action: Persistable, Doable, Codable, Sendable,
                      FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Persistable
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date
    
    // MARK: - Doable
    public var measuresByUnit: [String: Double]?
    public var durationMinutes: Double?
    public var startTime: Date?
    
    // MARK: - GRDB TableRecord
    public static let databaseTableName = "actions"
    
    // CodingKeys for snake_case ↔ camelCase mapping
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"                                      // Database column name
        case title
        case detailedDescription = "description"
        case freeformNotes = "notes"
        case measuresByUnit = "measurement_units_by_amount"
        case durationMinutes = "duration_minutes"
        case startTime = "start_time"
        case logTime = "log_time"
    }
    
    // Type-safe column references
    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        // ... etc
    }
    
    // UUID encoding strategy
    public static func databaseUUIDEncodingStrategy(for column: String) -> DatabaseUUIDEncodingStrategy {
        .uppercaseString  // Store as "550E8400-E29B-41D4-A716-446655440000"
    }
}
```

#### Goal Model (Polymorphic)

```swift
public struct Goal: Persistable, Completable, Polymorphable, Motivating,
                    Codable, Sendable, FetchableRecord, PersistableRecord, TableRecord {
    // MARK: - Persistable
    public var id: UUID
    public var title: String?
    public var detailedDescription: String?
    public var freeformNotes: String?
    public var logTime: Date
    
    // MARK: - Completable
    public var measurementUnit: String?
    public var measurementTarget: Double?
    public var startDate: Date?
    public var targetDate: Date?
    
    // MARK: - SMART Fields
    public var howGoalIsRelevant: String?
    public var howGoalIsActionable: String?
    
    // MARK: - Motivating
    public var priority: Int
    public var lifeDomain: String?
    
    // MARK: - Polymorphic
    public var polymorphicSubtype: String { "goal" }
    
    public static let databaseTableName = "goals"
    
    enum CodingKeys: String, CodingKey {
        case id = "uuid_id"
        case title
        case detailedDescription = "description"
        // ... map all properties to database columns
    }
}
```

### Layer 2: Business Logic (`Sources/BusinessLogic/`)

#### Matching Service

```swift
public struct MatchingService {
    /// Check if action falls within goal's time period
    public static func matchesOnPeriod(action: Action, goal: Goal) -> Bool {
        guard let actionTime = action.logTime else { return false }
        
        // If goal has no dates, all actions match
        guard let startDate = goal.startDate, let targetDate = goal.targetDate else {
            return true
        }
        
        return startDate <= actionTime && actionTime <= targetDate
    }
    
    /// Check if action measurement matches goal unit
    public static func matchesOnUnit(action: Action, goal: Goal) -> (matched: Bool, contribution: Double?) {
        guard let measurements = action.measuresByUnit,
              let goalUnit = goal.measurementUnit else {
            return (false, nil)
        }
        
        let normalizedUnit = goalUnit.lowercased().replacingOccurrences(of: " ", with: "_")
        
        for (key, value) in measurements {
            if key.lowercased().contains(normalizedUnit) {
                return (true, value)
            }
        }
        
        return (false, nil)
    }
    
    /// Calculate confidence score
    public static func calculateConfidence(periodMatch: Bool, actionabilityMatch: Bool) -> Double {
        if !periodMatch || !actionabilityMatch { return 0.0 }
        return 0.8  // Default confidence for inferred matches
    }
}
```

#### Inference Service (Actor)

```swift
public actor InferenceService {
    /// Thread-safe batch inference
    public func inferMatches(actions: [Action], goals: [Goal]) -> [ActionGoalRelationship] {
        var results: [ActionGoalRelationship] = []
        
        for action in actions {
            for goal in goals {
                let periodMatch = MatchingService.matchesOnPeriod(action: action, goal: goal)
                let unitMatch = MatchingService.matchesOnUnit(action: action, goal: goal)
                
                if periodMatch && unitMatch.matched, let contribution = unitMatch.contribution {
                    results.append(ActionGoalRelationship(
                        actionId: action.id,
                        goalId: goal.id,
                        contribution: contribution,
                        matchMethod: .autoInferred,
                        confidence: 0.8
                    ))
                }
            }
        }
        
        return results
    }
}
```

### Layer 3: Database (`Sources/Database/`)

#### DatabaseManager Actor

```swift
public actor DatabaseManager {
    private let dbPool: DatabasePool
    public let configuration: DatabaseConfiguration
    
    public init(configuration: DatabaseConfiguration = .default) async throws {
        self.configuration = configuration
        
        // Create database pool
        self.dbPool = try DatabasePool(path: configuration.databasePath.path)
        
        // Initialize schema if needed
        if !configuration.isInMemory {
            try await dbPool.write { db in
                try initializeSchema(db)
            }
        }
    }
    
    /// Generic fetch all
    public func fetchAll<T: FetchableRecord & Sendable>() async throws -> [T] {
        try await dbPool.read { db in
            try T.fetchAll(db)
        }
    }
    
    /// Generic save (insert or update)
    public func save<T: PersistableRecord & Sendable>(_ record: inout T) async throws {
        try await dbPool.write { db in
            try record.save(db)
        }
    }
    
    /// Fetch by ID
    public func fetchOne<T: FetchableRecord & Sendable>(_ type: T.Type, id: UUID) async throws -> T? {
        try await dbPool.read { db in
            try T.fetchOne(db, key: id)
        }
    }
}
```

**Key Difference from Python:**
- Python uses generic `Database` class that works with dicts
- Swift uses GRDB's native types that work directly with domain models
- No separate Record types needed (GRDB Codable handles serialization)

### Recent Architectural Achievement (Oct 22, 2025)

**Relationship System Complete:**
```swift
// Phase 1-3: Full relationship integration
struct ActionGoalRelationship: Codable, Sendable,
                              FetchableRecord, PersistableRecord, TableRecord {
    var uuid_id: UUID
    var actionId: UUID
    var goalId: UUID
    var contribution: Double
    var matchMethod: MatchMethod      // enum: autoInferred, userConfirmed, manual
    var confidence: Double
    var matchedOn: [MatchCriteria]    // enum: period, unit, description
    
    static let databaseTableName = "action_goal_progress"
    
    enum CodingKeys: String, CodingKey {
        case uuid_id, actionId = "action_id", goalId = "goal_id"
        case contribution, matchMethod = "match_method"
        case confidence, matchedOn = "matched_on"
    }
}
```

**Status:** 80 new tests (30 models + 37 business logic + 13 integration), 281 total passing

---

## Part 4: Database Schema (Shared Between Languages)

### Schema Files Location
`shared/schemas/` - Both Python and Swift read from here

### Key Table Definitions

#### actions.sql
```sql
CREATE TABLE IF NOT EXISTS actions (
    uuid_id TEXT PRIMARY KEY,                          -- UUID string (both Python & Swift use)
    title TEXT,                                        -- Short action name
    description TEXT,                                  -- Optional elaboration
    notes TEXT,                                        -- Freeform notes
    log_time TEXT NOT NULL,                            -- ISO 8601 datetime
    measurement_units_by_amount TEXT,                  -- JSON: {"km": 5.0, "minutes": 30}
    start_time TEXT,                                   -- ISO 8601 datetime
    duration_minutes REAL                              -- Float seconds/minutes
);
```

#### goals.sql (Supports Polymorphism)
```sql
CREATE TABLE IF NOT EXISTS goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,               -- Python legacy ID
  uuid_id TEXT UNIQUE,                                -- Swift UUID ID
  title TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  log_time TEXT NOT NULL,
  goal_type TEXT NOT NULL DEFAULT 'Goal',             -- ← TYPE IDENTIFIER (Goal, Milestone, SmartGoal)
  measurement_target REAL,                            -- Numeric goal
  measurement_unit TEXT,                              -- Unit of measure
  start_date TEXT,                                    -- ISO 8601
  target_date TEXT,                                   -- ISO 8601
  how_goal_is_relevant TEXT,                          -- SMART: Relevant
  how_goal_is_actionable TEXT,                        -- SMART: Actionable
  expected_term_length INTEGER                        -- Duration in weeks
);

CREATE INDEX IF NOT EXISTS idx_goals_uuid ON goals(uuid_id);
```

#### personal_values.sql (Polymorphic)
```sql
CREATE TABLE IF NOT EXISTS personal_values (
  id INTEGER PRIMARY KEY AUTOINCREMENT,               -- Python legacy
  uuid_id TEXT UNIQUE,                                -- Swift UUID
  title TEXT NOT NULL,
  description TEXT,
  notes TEXT,
  log_time TEXT NOT NULL,
  incentive_type TEXT NOT NULL,                       -- ← TYPE: 'general', 'major', 'highest_order', 'life_area'
  priority INTEGER NOT NULL DEFAULT 50,               -- 1-100
  life_domain TEXT DEFAULT 'General',                 -- Health, Relationships, etc.
  alignment_guidance TEXT                             -- Optional guidance text
);

CREATE INDEX IF NOT EXISTS idx_personal_values_uuid ON personal_values(uuid_id);
```

#### action_goal_progress.sql (Relationships)
```sql
CREATE TABLE IF NOT EXISTS action_goal_progress (
  uuid_id TEXT PRIMARY KEY,                           -- Relationship ID
  action_id TEXT NOT NULL,                            -- Foreign key to actions
  goal_id TEXT NOT NULL,                              -- Foreign key to goals
  contribution REAL NOT NULL,                         -- Amount contributed
  match_method TEXT NOT NULL,                         -- auto_inferred, user_confirmed, manual
  confidence REAL,                                    -- 0.0-1.0
  matched_on TEXT,                                    -- JSON array: ["period", "unit", "description"]
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (action_id) REFERENCES actions(uuid_id) ON DELETE CASCADE,
  FOREIGN KEY (goal_id) REFERENCES goals(uuid_id) ON DELETE CASCADE,
  UNIQUE(action_id, goal_id)
);
```

#### terms.sql
```sql
CREATE TABLE IF NOT EXISTS terms (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid_id TEXT UNIQUE,
  title TEXT NOT NULL,                                -- "Term 1", "Term 2", etc.
  number INTEGER NOT NULL,                            -- Week count: 10
  start_date TEXT NOT NULL,                           -- ISO 8601
  target_date TEXT NOT NULL,                          -- ISO 8601
  theme TEXT,                                         -- Optional theme
  term_goals_by_id TEXT,                              -- JSON array of goal UUIDs
  reflection TEXT,                                    -- End-of-term reflection
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

#### archive.sql (Audit Trail)
```sql
CREATE TABLE IF NOT EXISTS archive (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_table TEXT NOT NULL,                         -- Which table this came from
  source_id INTEGER,                                  -- Original record ID
  record_data TEXT NOT NULL,                          -- Full JSON record
  reason TEXT,                                        -- 'delete', 'update', 'manual'
  notes TEXT,                                         -- Additional context
  archived_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

### Database Compatibility Strategy

**Python:**
- Generates UUIDs at entity creation time
- Stores in `uuid_id TEXT` column
- `id INTEGER` column is auto-increment (legacy)
- Reads/writes JSON fields with `json.dumps()` / `json.loads()`

**Swift:**
- Generates UUIDs at entity creation time
- Stores in `uuid_id TEXT` column using GRDB's UUID encoding
- Uses `CodingKeys` for snake_case ↔ camelCase mapping
- Automatic JSON serialization via Codable

**Key Fact:** Both use TEXT storage for UUIDs (36-byte uppercase strings), making them fully interoperable.

---

## Part 5: Key Architectural Patterns

### Pattern 1: Layered Architecture with Strict Boundaries

**Problem:** How to separate concerns while maintaining testability?

**Solution:** Four-layer model with unidirectional dependencies

```
┌─────────────────────────────┐
│  Interfaces (CLI, Flask, SwiftUI)
│  - HTTP requests/responses
│  - User input handling
│  - Presentation formatting
└─────────────────────────────┘
         ↓ uses
┌─────────────────────────────┐
│  ethica (Business Logic)
│  - Pure functions, no side effects
│  - Domain rule implementation
│  - Fully testable without DB
└─────────────────────────────┘
         ↓ uses
┌─────────────────────────────┐
│  rhetorica (Translation)
│  - Entity ↔ dict conversion
│  - Polymorphic type handling
│  - Storage orchestration
└─────────────────────────────┘
         ↓ uses
┌─────────────────────────────┐
│  politica (Infrastructure)
│  - Raw SQL operations
│  - No domain knowledge
│  - Works with primitives only
└─────────────────────────────┘
         ↓ reads/writes
┌─────────────────────────────┐
│  categoriae (Domain Entities)
│  - Pure data structures
│  - Self-validation only
│  - Zero dependencies
└─────────────────────────────┘
```

**Critical Rule:** Each layer only knows about layers below it. No upward dependencies.

### Pattern 2: Polymorphic Storage via Type Field

**Problem:** How to store different class hierarchies (Goal/Milestone/SmartGoal) in same table?

**Solution:** Single-table inheritance with type discriminator field

```python
# Python Example
class GoalStorageService(StorageService[Goal]):
    CLASS_MAP = {
        'Goal': Goal,
        'Milestone': Milestone,
        'SmartGoal': SmartGoal
    }
    
    def _to_dict(self, goal: Goal) -> dict:
        return {
            'uuid_id': str(goal.uuid_id),
            'goal_type': goal.goal_type,  # ← "Goal", "Milestone", or "SmartGoal"
            # ... all other fields
        }
    
    def _from_dict(self, data: dict) -> Goal:
        goal_type = data.get('goal_type', 'Goal')
        goal_class = self.CLASS_MAP.get(goal_type, Goal)
        return goal_class(
            uuid_id=UUID(data['uuid_id']),
            # ... initialize from dict
        )
```

```swift
// Swift Example (via Codable custom init)
extension Goal {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let goalType = try container.decode(String.self, forKey: .polymorphicSubtype)
        
        switch goalType {
        case "Milestone":
            // Decode as Milestone with validation
            self = try Milestone(from: decoder)
        case "SmartGoal":
            // Decode as SmartGoal with validation
            self = try SmartGoal(from: decoder)
        default:
            // Decode as base Goal
            // ...
        }
    }
}
```

**Result:** Single table, multiple types, automatic round-trip preservation of class information.

### Pattern 3: Business Logic as Pure Functions

**Problem:** How to make business logic testable without framework overhead?

**Solution:** All business logic in simple, pure functions

```python
# ethica/progress_matching.py - NO DATABASE, NO SIDE EFFECTS
def matches_on_period(action: Action, goal: Goal) -> bool:
    """Pure function - no database calls, no mutations"""
    if not action.log_time:
        return False
    if not goal.start_date or not goal.target_date:
        return True
    return goal.start_date <= action.log_time <= goal.target_date

# Test this without database setup:
def test_matches_on_period():
    action = Action(log_time=datetime(2025, 10, 15))
    goal = Goal(start_date=datetime(2025, 10, 1), target_date=datetime(2025, 10, 31))
    assert matches_on_period(action, goal) == True  # ✓ No database needed!
```

**Benefit:** Can test 90+ business logic scenarios in seconds without database overhead.

### Pattern 4: Generic Storage with Type-Safe Operations

**Problem:** How to build one storage layer that works for Actions, Goals, Values, Terms?

**Solution:** Generic base class with overridable translation methods

```python
class StorageService(ABC, Generic[T]):
    """Generic base - subclasses only override _to_dict() and _from_dict()"""
    
    def store_single_instance(self, entry: T) -> T:
        """Identical for all entities"""
        entity_dict = self._to_dict(entry)  # Subclass implements
        db_id = self.db.insert(self.table_name, [entity_dict])
        entry.id = db_id[0]
        return entry
    
    def get_all(self, filters: Optional[dict] = None) -> List[T]:
        """Works for any entity"""
        records = self.db.query(self.table_name, filters=filters)
        return [self._from_dict(record) for record in records]  # Subclass implements

class ActionStorageService(StorageService[Action]):
    table_name = 'actions'
    
    def _to_dict(self, action: Action) -> dict:
        return {'uuid_id': str(action.uuid_id), 'title': action.title, ...}
    
    def _from_dict(self, data: dict) -> Action:
        return Action(uuid_id=UUID(data['uuid_id']), title=data['title'], ...)
```

**Result:** New entities only require implementing `_to_dict()` and `_from_dict()`. All CRUD operations inherited.

### Pattern 5: Relationship Inference via Stateless Services

**Problem:** How to automatically detect which actions contribute to goals?

**Solution:** Separate inference service orchestrating matching functions

```python
# ethica/inference_service.py
class ActionGoalInferenceService:
    def __init__(self, action_service, goal_service):
        self.action_service = action_service
        self.goal_service = goal_service
    
    def infer_for_period(self, start_date, target_date) -> InferenceSession:
        # Fetch entities (rhetorica)
        actions = self.action_service.get_all()
        goals = self.goal_service.get_all()
        
        # Run pure matching logic (ethica)
        all_matches = infer_matches(
            actions=actions,
            goals=goals,
            require_period_match=True
        )
        
        # Organize results
        confident, ambiguous = filter_ambiguous_matches(all_matches, threshold=0.7)
        
        return InferenceSession(
            actions_analyzed=len(actions),
            goals_analyzed=len(goals),
            confident_matches=confident,
            ambiguous_matches=ambiguous,
            unmatched_actions=[a for a in actions if not any(m.action == a for m in all_matches)]
        )
```

**Key:** Service is orchestrator, not implementer. All logic delegated to pure functions.

---

## Part 6: Technology Stack Comparison

### Python Implementation

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Database** | SQLite3 | Simple file-based persistence |
| **ORM** | None (manual dicts) | Intentional - keeps layer boundaries clear |
| **Testing** | pytest | Fixture-based test isolation |
| **Web Framework** | Flask | Lightweight, route-based |
| **Serialization** | json module | Standard library only |
| **Type Hints** | dataclasses | Structure + type safety |
| **Concurrency** | None (sync) | Single-threaded, simple |

### Swift Implementation

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Database** | GRDB.swift 7.8.0 | Type-safe SQLite with Codable |
| **ORM** | GRDB (native) | Domain models conform directly |
| **Testing** | XCTest | Platform standard |
| **UI Framework** | SwiftUI | Native macOS/iOS |
| **Serialization** | Codable (auto) | Zero-boilerplate JSON |
| **Type Hints** | Swift 6.2 protocols | Compile-time safety |
| **Concurrency** | async/await + actors | Swift 6 strict concurrency |

### Key Differences

1. **Python**: Manual serialization (write _to_dict/from_dict for each entity)
2. **Swift**: Automatic serialization (Codable + CodingKeys mapping)

3. **Python**: Synchronous (blocking operations)
4. **Swift**: Asynchronous (all DB operations `async throws`)

5. **Python**: Duck typing (StorageService works with anything)
6. **Swift**: Protocol composition (must conform to specific protocols)

---

## Part 7: Testing Patterns

### Python Testing Strategy

```python
# tests/test_actions.py
import pytest
from categoriae.actions import Action
from datetime import datetime

def test_action_creation():
    action = Action(title="Morning run", description="5km run")
    assert action.title == "Morning run"
    assert action.log_time is not None

def test_action_validation():
    action = Action(title="Run")
    action.measurement_units_by_amount = {"km": -5.0}
    assert action.is_valid() == False  # Negative measurements invalid

@pytest.fixture
def in_memory_db():
    """Fixture: provides clean database for each test"""
    db = Database(db_path=':memory:', schema_path=SCHEMA_PATH)
    yield db

def test_action_roundtrip(in_memory_db):
    """Test: save and retrieve"""
    service = ActionStorageService(in_memory_db)
    action = Action(title="Run", uuid_id=UUID('123e4567-e89b-12d3-a456-426614174000'))
    
    service.store_single_instance(action)
    retrieved = service.get_by_uuid(action.uuid_id)
    
    assert retrieved.title == "Run"
```

**Status:** 90 tests passing across:
- Domain models (9 tests)
- Values hierarchy (8 tests)
- Progress aggregation (12 tests)
- Storage roundtrip (3 tests)
- Polymorphic storage (multiple tests)
- Term actions filtering (2 tests)

### Swift Testing Strategy

```swift
// Tests/ActionTests.swift
import XCTest
@testable import Models

final class ActionTests: XCTestCase {
    func testActionCreation() {
        let action = Action(title: "Morning run")
        
        XCTAssertEqual(action.title, "Morning run")
        XCTAssertNotNil(action.id)
        XCTAssertNotNil(action.logTime)
    }
}

// Tests/IntegrationTests/ActionGRDBTests.swift
final class ActionGRDBTests: XCTestCase {
    var database: DatabaseManager!
    
    override func setUp() async throws {
        database = try await DatabaseManager(configuration: .inMemory)
    }
    
    func testActionRoundTrip() async throws {
        var action = Action(title: "Test run")
        action.measuresByUnit = ["km": 5.0]
        
        try await database.save(&action)  // Save with GRDB
        
        let retrieved = try await database.fetchOne(Action.self, id: action.id)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Test run")
        XCTAssertEqual(retrieved?.measuresByUnit?["km"], 5.0)
    }
}
```

**Status:** 281 tests passing including:
- Domain model tests (30)
- Business logic tests (37)
- Database integration tests (13)
- View model tests (20+)

---

## Part 8: Important Implementation Details

### ID Management Strategy

**Python:**
```python
# Uses both INTEGER (legacy) and UUID (modern)
@dataclass
class PersistableEntity:
    uuid_id: UUID = field(default_factory=uuid4, kw_only=True)
    id: Optional[int] = field(default=None, kw_only=True)  # Populated by database
```

**Swift:**
```swift
// Uses UUID only (generated at creation time)
public struct Action: Persistable {
    public var id: UUID = UUID()  // Generate immediately, no database round-trip
}
```

**Database:**
```sql
-- actions.sql
CREATE TABLE actions (
    uuid_id TEXT PRIMARY KEY,  -- Both Python and Swift use this
    -- No separate id INTEGER column anymore
)

-- goals.sql (maintains backward compatibility)
CREATE TABLE goals (
    id INTEGER PRIMARY KEY,    -- Python legacy, still populated
    uuid_id TEXT UNIQUE,       -- Swift native
)
```

### Measurement Storage

All measurements stored as **JSON TEXT** for flexibility:

```sql
measurement_units_by_amount TEXT  -- Example: '{"km":5.0,"minutes":30}'
```

**Python:**
```python
action.measurement_units_by_amount = {"km": 5.0, "minutes": 30}
# Stored as: json.dumps(action.measurement_units_by_amount)
```

**Swift:**
```swift
action.measuresByUnit = ["km": 5.0, "minutes": 30]
// Stored automatically via Codable (GRDB handles serialization)
```

### Date/Time Storage

All dates stored as **ISO 8601 TEXT** for cross-platform compatibility:

```sql
log_time TEXT NOT NULL  -- Example: '2025-10-23T14:30:45Z'
```

**Python:**
```python
action.log_time = datetime.now()
# Stored as: action.log_time.isoformat()
```

**Swift:**
```swift
action.logTime = Date()
// Stored via Codable with ISO8601 strategy
```

### Error Handling Patterns

**Python:**
```python
try:
    service = GoalStorageService()
    goals = service.get_all()
    # ... processing
except Exception as e:
    logger.error(f"Error fetching goals: {e}", exc_info=True)
    return jsonify({'error': str(e)}), 500
```

**Swift:**
```swift
do {
    let goals: [Goal] = try await database.fetchAll()
    // ... processing
} catch let error as DatabaseError {
    print("Database error: \(error)")
    return .failure(error)
}
```

---

## Part 9: Implications for JavaScript Implementation

### What a JS Implementation Would Need

1. **Same Layered Architecture**
   - Domain models (no dependencies)
   - Business logic (pure functions)
   - Translation layer (entity ↔ dict)
   - Infrastructure (database operations)
   - Interfaces (HTTP/CLI)

2. **Same Domain Classes**
   - Action, Goal (with Milestone/SmartGoal subclasses), Value (with hierarchy)
   - Relationships (ActionGoalRelationship, etc.)
   - All with UUID + validation

3. **Same Database Interaction**
   - Read/write same SQLite database
   - Use same schema files
   - Handle polymorphic storage (goal_type, incentive_type fields)
   - Support JSON columns for measurements

4. **Same Business Logic**
   - Action-goal matching algorithms
   - Progress aggregation
   - Inference service for batch processing
   - Term lifecycle management

5. **Similar Testing Approach**
   - Unit tests for domain models
   - Integration tests for storage roundtrip
   - No mocks needed (test with real objects)

### Language-Specific Decisions for JS

| Question | Python Example | Swift Example | JS Decision? |
|----------|-----------------|----------------|-------------|
| **Dataclass pattern** | Python dataclasses | Swift structs | TypeScript interfaces + classes |
| **Serialization** | Manual dict translation | Codable + CodingKeys | JSON.stringify with property mapping |
| **Polymorphism** | Type field + CLASS_MAP | Codable custom init | Discriminator field + factory pattern |
| **Async pattern** | Sync only | async/await | Promises / async-await (Node.js) |
| **Testing** | pytest fixtures | XCTest | Jest or Vitest |
| **Database** | sqlite3 module | GRDB.swift | better-sqlite3 or TypeORM |
| **Type safety** | Type hints | Swift 6 protocols | TypeScript strict mode |

### Estimated Implementation Effort

Based on Python (2500+ LOC) and Swift (2000+ LOC):

- **Domain Models (categoriae/)**: 2-3 hours
  - 5 entity types with validation
  - Inheritance/composition patterns
  - Simple classes with properties

- **Business Logic (ethica/)**: 3-4 hours
  - 4 modules (inference, matching, progress, term lifecycle)
  - Pure functions, moderate complexity

- **Translation Layer (rhetorica/)**: 2-3 hours
  - Generic storage service pattern
  - Polymorphic type handling
  - Entity ↔ dict conversions

- **Infrastructure (politica/)**: 1-2 hours
  - SQL query building
  - Generic CRUD operations
  - Archiving logic

- **Interfaces (Flask equivalent)**: 4-5 hours
  - REST API endpoints (27 endpoints)
  - JSON serialization/deserialization
  - Error handling

- **Testing**: 6-8 hours
  - Domain model tests (30+)
  - Business logic tests (40+)
  - Integration tests (20+)

**Total Estimate:** 18-25 hours for MVP (matching Python functionality)

---

## Conclusion

The Ten Week Goal App demonstrates how clean architecture principles can be consistently applied across multiple language implementations while maintaining a shared database. The key insights for a JavaScript port are:

1. **Layers are more important than language idioms** - Both Python and Swift maintain identical separation of concerns
2. **Database compatibility through standards** - UUID TEXT, ISO8601 dates, JSON columns work across all languages
3. **Business logic is language-agnostic** - Pure functions can be easily ported with minimal changes
4. **Type information in data** - Polymorphic storage via type fields eliminates the need for complex table designs
5. **Testing is comprehensive** - 90+ Python tests provide a specification for expected behavior
