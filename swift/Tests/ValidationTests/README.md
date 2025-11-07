# Validation Tests

## Purpose
Answer the question: **Do validators correctly enforce business rules?**

## Why These Tests Matter
Validators are the first line of defense against invalid data. The code *looks* like it checks rules, but:
- Does it handle edge cases correctly?
- Does it provide useful error messages?
- Does the entity graph validation catch inconsistencies that individual field validation misses?

## What We're NOT Testing
- ❌ Type conformance (compiler does this)
- ❌ That ValidationError has certain cases (obvious from reading the enum)
- ❌ That validator methods exist (obvious from reading the protocol)

## What We ARE Testing
- ✅ Business rules are correctly implemented (empty action rejected, but action with only measurements accepted)
- ✅ Edge cases work as expected (very long titles, boundary values for ranges)
- ✅ Error messages are actionable ("Action must have title OR measurements" not just "invalid")
- ✅ Entity graph validation catches ID mismatches that wouldn't be obvious

## Test Files
- `ActionValidatorTests.swift` - "Can empty actions slip through? Do negative durations fail?"
- `GoalValidatorTests.swift` - "Does importance range validation actually enforce 1-10? What about date ordering?"
- `TermValidatorTests.swift` - "Can terms overlap? Do date ranges validate correctly?"
- `ValueValidatorTests.swift` - "Does priority validation work? Can duplicate titles exist?"
- `ValidationErrorTests.swift` - "Are error messages user-friendly? Do they suggest fixes?"
