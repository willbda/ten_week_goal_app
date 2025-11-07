// CRUDWorkflowTests.swift
// Created: 2025-11-06
//
// PURPOSE: Test complete user workflows from FormView → ViewModel → Coordinator → Database → Query → ListView
//
// GENUINE QUESTIONS THIS FILE ANSWERS:
//
// 1. FULL DATA CYCLE:
//    Q: When user creates PersonalValue, can they immediately query it back?
//    Q: Does created data persist across app restarts? (database write succeeded)
//    Q: Are all fields preserved in round trip?
//    Why: Data could be cached in ViewModel, not actually written to DB.
//
// 2. UPDATE COMPLETENESS:
//    Q: When user updates entity, do changes actually persist?
//    Q: Are old values fully replaced (not partially)?
//    Q: Can updated entity be queried and show new values?
//    Why: Update might succeed but not write to disk, or leave stale data.
//
// 3. DELETE COMPLETENESS:
//    Q: When user deletes entity, is it truly gone from database?
//    Q: Does query return empty after delete?
//    Q: Can we recreate entity with same title after delete?
//    Why: Delete might be soft delete or leave orphaned records.
//
// 4. CROSS-COMPONENT INTEGRATION:
//    Q: FormViewModel.save() → CoordinatorCreate() → DatabaseWrite() → QueryFetch() all work together?
//    Q: Are there any data type mismatches in the chain?
//    Q: Do IDs propagate correctly through all layers?
//    Why: Integration bugs hide in component boundaries.
//
// 5. REALISTIC USER FLOWS:
//    Q: Can user create → edit → delete in sequence without errors?
//    Q: Can user create multiple entities in quick succession?
//    Q: Can user delete and recreate with same data?
//    Why: Real usage patterns might expose race conditions or state issues.
//
// WHAT WE'RE NOT TESTING:
// - SwiftUI rendering (that's UI tests with Xcode)
// - Button tap handling (that's UI tests)
// - Individual component logic (tested in unit/integration tests)
//
// TEST STRUCTURE:
// - Use persistent DatabaseQueue (not in-memory) to test disk writes
// - Simulate user actions via ViewModel methods
// - Query database directly to verify state
// - Test complete workflows, not individual operations

import Foundation
import Testing
import SQLiteData
@testable import App
@testable import Services
@testable import Models

@Suite("CRUD Workflows - Complete User Flows")
struct CRUDWorkflowTests {

    // MARK: - Test Questions: PersonalValue CRUD Flow

    // Q: Can user create PersonalValue and immediately see it in list?
    // How to test:
    //   1. Create PersonalValue via ViewModel.save()
    //   2. Execute PersonalValuesQuery
    //   3. Verify created value appears in results
    // Why: Proves FormView → ViewModel → Coordinator → Database → Query → ListView chain works
    // @Test("User Flow: Create PersonalValue → Query retrieves it")

    // Q: Can user update PersonalValue and see changes in list?
    // How to test:
    //   1. Create value with title "Health"
    //   2. Update to title "Fitness"
    //   3. Query database
    //   4. Verify shows "Fitness" not "Health"
    // Why: Proves update persists and query reflects changes
    // @Test("User Flow: Update PersonalValue → Query shows new data")

    // Q: Can user delete PersonalValue and it disappears from list?
    // How to test:
    //   1. Create value
    //   2. Query, verify exists
    //   3. Delete value
    //   4. Query, verify gone
    // Why: Proves delete fully removes from database
    // @Test("User Flow: Delete PersonalValue → Query returns empty")

    // Q: Can user create → update → delete in single session?
    // How to test: Run all 3 operations in sequence, verify each step works
    // Why: Proves no state corruption between operations
    // @Test("User Flow: Create → Update → Delete sequence succeeds")

    // MARK: - Test Questions: Action with Measurements CRUD Flow

    // Q: Can user log action with measurements and query it back?
    // How to test:
    //   1. Create Measure "km" in database
    //   2. Create Action via ViewModel with measurement (km, 5.0)
    //   3. Execute ActionsQuery
    //   4. Verify action has measurement with value 5.0
    // Why: Proves multi-model creation and query work end-to-end
    // @Test("User Flow: Log action with measurement → Query retrieves both")

    // Q: Can user update action to add new measurement?
    // How to test:
    //   1. Create action with 1 measurement
    //   2. Update to add 2nd measurement
    //   3. Query, verify both measurements present
    // Why: Proves update handles relationship additions
    // @Test("User Flow: Update action add measurement → Query shows both")

    // Q: Can user update action to remove measurement?
    // How to test:
    //   1. Create action with 2 measurements
    //   2. Update to remove 1 measurement
    //   3. Query, verify only 1 measurement remains
    // Why: Proves update handles relationship removals
    // @Test("User Flow: Update action remove measurement → Query shows one")

    // Q: Can user delete action and measurements cascade?
    // How to test:
    //   1. Create action with 2 measurements
    //   2. Delete action
    //   3. Query MeasuredAction table directly
    //   4. Verify 0 rows for that actionId
    // Why: Proves cascade delete works
    // @Test("User Flow: Delete action → Measurements cascade deleted")

    // Q: After deleting action, do Measure catalog entries survive?
    // How to test:
    //   1. Create action with km measurement
    //   2. Delete action
    //   3. Query Measures table
    //   4. Verify km Measure still exists
    // Why: Proves cascade doesn't delete too broadly
    // @Test("User Flow: Delete action → Measure catalog preserved")

    // MARK: - Test Questions: Goal Multi-Model CRUD Flow

    // Q: Can user create goal with targets and alignments?
    // How to test:
    //   1. Create Measures (km, sessions) and PersonalValue (Health)
    //   2. Create Goal via ViewModel with 2 targets + 1 alignment
    //   3. Execute GoalsQuery
    //   4. Verify goal has all 5 models (Expectation, Goal, 2 Measures, 1 Relevance)
    // Why: Proves most complex multi-model creation works end-to-end
    // @Test("User Flow: Create goal with targets+alignments → Query retrieves all")

    // Q: Can user update goal to change targets?
    // How to test:
    //   1. Create goal with 1 target (km: 100)
    //   2. Update to 2 targets (km: 100, sessions: 20)
    //   3. Query, verify both targets exist
    // Why: Proves complex update handles relationship changes
    // @Test("User Flow: Update goal targets → Query shows new targets")

    // Q: When user updates goal, are old targets removed?
    // How to test:
    //   1. Create goal with target (km: 100)
    //   2. Update to target (sessions: 20) - km removed
    //   3. Query ExpectationMeasures directly
    //   4. Verify no km target, only sessions target
    // Why: Proves update cleans up old relationships (no orphans)
    // @Test("User Flow: Update goal targets → Old targets removed")

    // Q: Can user delete goal and all relationships cascade?
    // How to test:
    //   1. Create goal with 2 targets + 2 alignments
    //   2. Delete goal
    //   3. Query Expectation, Goal, ExpectationMeasure, GoalRelevance tables
    //   4. Verify all rows for that goal are gone
    // Why: Proves complex cascade delete works
    // @Test("User Flow: Delete goal → All 5 models cascade deleted")

    // Q: After deleting goal, do referenced Values survive?
    // How to test:
    //   1. Create goal aligned with "Health" value
    //   2. Delete goal
    //   3. Query PersonalValues
    //   4. Verify "Health" still exists
    // Why: Proves cascade doesn't delete referenced entities
    // @Test("User Flow: Delete goal → Referenced values preserved")

    // MARK: - Test Questions: Edge Cases & Real Usage

    // Q: Can user create 10 entities in quick succession?
    // How to test: Loop create 10 PersonalValues, query, verify all 10 exist
    // Why: Tests for race conditions or transaction conflicts
    // @Test("User Flow: Rapid creation of 10 entities succeeds")

    // Q: Can user delete and recreate entity with same title?
    // How to test:
    //   1. Create "Health"
    //   2. Delete "Health"
    //   3. Create "Health" again
    //   4. Verify succeeds (no unique constraint violation if deleted)
    // Why: Proves delete fully removes (not soft delete with UNIQUE constraint)
    // @Test("User Flow: Delete → Recreate with same title succeeds")

    // Q: What happens if user tries to update non-existent entity?
    // How to test: Try to update with random UUID, expect error
    // Why: Proves error handling works end-to-end
    // @Test("User Flow: Update non-existent entity → Error shown")

    // Q: What happens if user tries to delete non-existent entity?
    // How to test: Try to delete with random UUID, expect error
    // Why: Proves error handling works
    // @Test("User Flow: Delete non-existent entity → Error shown")

    // MARK: - Test Questions: Cross-Entity Workflows

    // Q: Can user create term and assign 3 goals to it?
    // How to test:
    //   1. Create 3 goals
    //   2. Create term
    //   3. Assign all 3 goals to term (TermGoalAssignment)
    //   4. Query TermsWithGoals
    //   5. Verify term shows all 3 goals
    // Why: Proves cross-entity relationships work
    // @Test("User Flow: Create term → Assign goals → Query shows assignments")

    // Q: Can user create value and align 2 goals to it?
    // How to test:
    //   1. Create value "Health"
    //   2. Create 2 goals both aligned with "Health"
    //   3. Query by value
    //   4. Verify both goals show up
    // Why: Proves reverse relationship queries work
    // @Test("User Flow: Create value → Align goals → Query shows alignments")
}
