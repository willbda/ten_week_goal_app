# Architecture Reevaluation - October 25, 2025

**Status:** Swift implementation needs comprehensive rearchitecture
**Decision:** Pause feature development, reassess data structures → protocols → views

---

## Current State Analysis

### What I Examined
1. **Data Structures**: Action.swift, Goals.swift, Protocols.swift
2. **Views**: ActionFormView.swift (forms convert between struct ↔ @State)
3. **Design System**: DesignSystem.swift (spacing tokens, zoom system)
4. **Documentation**: Claims 90% complete, but...

### Reality Check

**I threw something minimal together to get it on my phone to test.**

This is the key insight. Current implementation is:
- Functional enough to test
- Not architecturally sound for production
- Has accumulated complexity without clear benefit
- Design language is absent/immature

---

## Key Problem Areas

### 1. Data Structures vs. Serialization

**Current State:**
```swift
@Table
public struct Action: Persistable, Doable, Sendable {
    public var title: String?  // Optional
    public var measuresByUnit: [String: Double] = [:]  // JSON storage
    public var durationMinutes: Double?  // Optional
    // ... 8 more properties
}
```

**Issues:**
- ✅ SQLiteData @Table handles database serialization automatically
- ❌ Too many optional fields → SwiftUI form pain (unwrapping everywhere)
- ❌ `measuresByUnit` as dictionary is awkward in UI (converting to/from arrays)
- ❓ Should structs be more "record-like" (closer to database) or more "domain-like" (closer to use cases)?

**Questions:**
1. Should we embrace "database-first" design (structs = database rows)?
2. Or "UI-first" design (separate ViewModels, DTOs for forms)?
3. What's the boundary between persistence and presentation?

### 2. Protocol System Complexity

**Current Protocols:**
- **Ontological**: Persistable, Completable, Doable, Motivating (4 protocols)
- **Infrastructure**: Validatable, Polymorphable, Serializable, JSONSerializable, Archivable (5 protocols)
- **Total**: 9 protocols for 4 entity types

**Issues:**
- ❓ Are these solving real problems or adding ceremony?
- ❓ Serializable + JSONSerializable exist, but SQLiteData + Codable might make them redundant
- ❓ Polymorphable adds complexity - do we need Goal/Milestone as separate types?
- ✅ Temporal separation (Completable vs Doable) is philosophically sound
- ❌ But does philosophy serve the app, or is the app serving the philosophy?

**Key Question:**
> "Does apparent complexity indicate a design problem that should be simplified?"

### 3. SwiftUI ↔ Data Structure Mismatch

**Current Pattern** (ActionFormView.swift):
```swift
// Struct has optional String
let actionToEdit: Action?

// Form needs non-optional @State
@State private var title: String

// Initialization = unwrapping ceremony
_title = State(initialValue: action?.title ?? "")
```

**Issues:**
- Every form converts: `Action` → 12 separate `@State` vars → `Action`
- Dictionary properties (`measuresByUnit`) → array (`[MeasurementItem]`) → dictionary
- Lots of unwrapping, mapping, defaulting

**Questions:**
1. Should structs have fewer optionals (required fields + builder pattern)?
2. Should forms work with ViewModels instead of raw structs?
3. Is the struct shape fighting SwiftUI or helping it?

### 4. Design Language Absence

**Current State:**
```swift
enum DesignSystem {
    enum Spacing { /* zoom-scaled tokens */ }
    enum Colors { /* semantic colors */ }
    enum Typography { /* fixed sizes */ }
}
```

**What's Missing:**
- ❌ No visual design language defined (what does this app *look like*?)
- ❌ No component library (buttons, cards, lists)
- ❌ No accessibility (VoiceOver labels, Dynamic Type)
- ⚠️ Custom zoom exists but should migrate to system Dynamic Type
- ⚠️ Color system not validated for contrast (WCAG)

**This is "design system as afterthought" not "design system as foundation"**

### 5. Generalization Opportunities

**Current Issues:**
- Goal and Milestone are separate structs with 90% overlap
- Polymorphic subtype field adds database complexity
- Could these be one struct with different configurations?

**Example Simplification:**
```swift
// Instead of:
struct Goal: Completable { var polymorphicSubtype = "goal" }
struct Milestone: Completable { var polymorphicSubtype = "milestone" }

// Consider:
struct Goal: Completable {
    var type: GoalType  // enum { case goal, milestone }
}
```


---

### Priority Order for Rearchitecture

Based on both the reevaluation AND this audit, tackle in this order:

1. **Data structures** (1-2 days)
   - Reduce optionals
   - Fix dictionary→array pain points
   - Make structs SwiftUI-friendly

2. **Protocol simplification** (1 day)
   - Challenge each of 9 protocols: "What problem does this solve?"
   - Remove philosophical abstractions that don't serve the app
   - Keep only protocols that reduce duplication or enable polymorphism

3. **Design language** (2-3 days)
   - Define visual identity BEFORE implementing
   - Build component library
   - Establish patterns

4. **Documentation** (1 day)
   - Comprehensive rewrite after architecture stabilizes
   - Single source of truth
   - Verify all examples compile


---

## Questions for Decision

### Data Architecture
1. **Serialization-first**: Should structs mirror database schema exactly?
2. **Field optionality**: Which fields should be required vs. optional?
3. **Dictionary fields**: Keep `[String: Double]` or use structured types?
4. **Validation**: Where does validation live (struct methods? separate layer?)

### Protocol System
1. **Protocol count**: Are 9 protocols justified, or can we simplify?
2. **Codable sufficiency**: Does SQLiteData + Codable replace Serializable/JSONSerializable?
3. **Polymorphism need**: Do we need separate types or just configuration?
4. **Philosophy vs. pragmatism**: Keep temporal ontology or simplify?

### SwiftUI Integration
1. **Form patterns**: Convert structs to @State, or use ViewModels?
2. **Binding strategy**: Two-way bindings vs. local state + save?
3. **Validation UI**: How to show validation errors from structs?

### Design Language
1. **Design-first**: Should we define visual language before implementing?
2. **Component library**: Build reusable components or keep ad-hoc?
3. **Accessibility**: When to integrate (now or later)?
4. **Typography**: Migrate to Dynamic Type or keep custom zoom?

---

## Rearchitecture Scope Estimate

### If We Simplify Radically
**Goal**: Minimal viable data structures, remove unnecessary abstraction

**Changes:**
- Collapse protocol hierarchy (keep 2-3 core protocols)
- Reduce optionals (builder pattern for progressive enhancement)
- Flatten polymorphism (Goal.type enum instead of separate structs)
- Remove Serializable (rely on Codable)
- Define visual design language first
- Build component library

**Effort**: 15-25 hours
**Risk**: Medium (existing code needs rewrite)
**Benefit**: Simpler codebase, faster development going forward

### If We Evolve Incrementally
**Goal**: Keep philosophy, improve SwiftUI integration

**Changes:**
- Add ViewModels for forms (keep structs as-is)
- Build design language on top of current system
- Add accessibility incrementally
- Keep protocol system but document "why"

**Effort**: 10-15 hours
**Risk**: Low (additive changes)
**Benefit**: Preserves investment, but complexity remains

### If We Start Fresh (Not Recommended)
**Goal**: Clean slate with lessons learned

**Effort**: 40-60 hours
**Risk**: Very high (lose progress)
**Benefit**: Clean architecture, but significant time cost

---

## Recommended Next Steps

1. **Stop saying "90% complete"** - Be honest about current state
2. **Version as 0.5.0** - Foundation laid, rearchitecture pending
3. **Create decision documents** for each problem area:
   - Data structure philosophy
   - Protocol justification (or removal)
   - SwiftUI integration patterns
   - Design language definition
4. **Prototype alternatives** in a branch before committing
5. **Measure complexity** - count protocols, optionals, mapping code
6. **Ask "why" repeatedly** - challenge every abstraction

---

## Version Update

**Old assessment**: 0.8.0 (90% complete)
**Realistic assessment**: 0.5.0 (foundation laid, needs rearchitecture)

**Rationale**:
- Core concepts proven (SQLiteData works, protocols compile)
- But not production-ready architecture
- Significant rework needed before 1.0

---

## Open Questions for David

1. **What feels wrong?** Specifically, what makes you want to rearchitect?
2. **What feels right?** What should we preserve?
3. **Design language**: Do you have visual references? (Apps you like, design styles)
4. **Complexity tolerance**: Simple & pragmatic, or elegant & principled?
5. **Timeline pressure**: Is there a deadline, or can we take time to get it right?

---

**Written by Claude Code on 2025-10-25**
**Next step**: Pause, discuss, decide
