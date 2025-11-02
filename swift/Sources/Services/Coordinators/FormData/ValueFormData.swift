import Foundation
import Models

public struct ValueFormData {
    public let title: String
    public let detailedDescription: String?
    public let freeformNotes: String?
    public let valueLevel: ValueLevel
    public let priority: Int?
    public let lifeDomain: String?
    public let alignmentGuidance: String?

    public init(
        title: String,
        detailedDescription: String? = nil,
        freeformNotes: String? = nil,
        valueLevel: ValueLevel,
        priority: Int? = nil,
        lifeDomain: String? = nil,
        alignmentGuidance: String? = nil
    ) {
        self.title = title
        self.detailedDescription = detailedDescription
        self.freeformNotes = freeformNotes
        self.valueLevel = valueLevel
        self.priority = priority
        self.lifeDomain = lifeDomain
        self.alignmentGuidance = alignmentGuidance
    }
}
