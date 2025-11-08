import Foundation

public enum CoordinatorError: Error, LocalizedError {
    // Validation errors
    case missingRequiredField(String)
    case invalidFormat(field: String, expected: String)
    case invalidDateRange(start: Date, end: Date)

    // Relationship errors
    case measureNotFound(UUID)
    case valueNotFound(UUID)
    case goalNotFound(UUID)
    case termNotFound(UUID)

    // Transaction errors
    case constraintViolation(String)
    case concurrentModification
    case validationFailed([CoordinatorError])

    public var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field):
            return "Required field missing: \(field)"
        case .invalidFormat(let field, let expected):
            return "\(field) has invalid format (expected: \(expected))"
        case .invalidDateRange(let start, let end):
            return "Start date (\(start)) must be before end date (\(end))"
        case .measureNotFound(let id):
            return "Metric not found: \(id)"
        case .valueNotFound(let id):
            return "Value not found: \(id)"
        case .goalNotFound(let id):
            return "Goal not found: \(id)"
        case .termNotFound(let id):
            return "Term not found: \(id)"
        case .constraintViolation(let message):
            return "Database constraint violated: \(message)"
        case .concurrentModification:
            return "Data was modified by another process. Please retry."
        case .validationFailed(let errors):
            return "Validation failed: \(errors.count) errors"
        }
    }
}
