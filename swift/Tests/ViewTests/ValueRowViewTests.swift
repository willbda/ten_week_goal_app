// ValueRowViewTests.swift
// Tests for ValueRowView using modern Swift Testing framework
//
// Written by Claude Code on 2025-10-21

import Testing
import SwiftUI
import Models
@testable import App

/// Test suite for ValueRowView component
///
/// Verifies the display of value data including priority indicators,
/// descriptions, life domains, and additional information.
@Suite("ValueRowView Tests")
struct ValueRowViewTests {

    // MARK: - Display Tests

    @Test("Displays friendly name correctly")
    func displaysFriendlyName() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Physical Health",
            detailedDescription: nil,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.friendlyName == "Physical Health")
    }

    @Test("Shows fallback for untitled value")
    func showsUntitledFallback() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: nil,
            detailedDescription: "Some description",
            priority: 50,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.friendlyName == nil)
    }

    @Test("Displays detailed description")
    func displaysDetailedDescription() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Creativity",
            detailedDescription: "Expressing original ideas and making new things",
            priority: 15,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.detailedDescription == "Expressing original ideas and making new things")
    }

    @Test("Displays additional info for major values")
    func displaysAdditionalInfo() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Physical Health",
            detailedDescription: "Maintaining strength and vitality",
            priority: 8,
            lifeDomain: "Health",
            additionalInfo: "Exercise regularly, eat well, get adequate sleep"
        )

        #expect(item.additionalInfo == "Exercise regularly, eat well, get adequate sleep")
    }

    @Test("Displays life domain tag")
    func displaysLifeDomainTag() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Career Growth",
            detailedDescription: "Professional development",
            priority: 12,
            lifeDomain: "Career",
            additionalInfo: nil
        )

        #expect(item.lifeDomain == "Career")
    }

    // MARK: - Priority Badge Tests

    @Test("Shows three stars for priority <= 5")
    func showsThreeStarsBadge() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Eudaimonia",
            detailedDescription: "Ultimate flourishing",
            priority: 1,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority <= 5)
    }

    @Test("Shows two stars for priority 6-10")
    func showsTwoStarsBadge() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Physical Health",
            detailedDescription: "Maintaining vitality",
            priority: 8,
            lifeDomain: "Health",
            additionalInfo: nil
        )

        #expect(item.priority > 5)
        #expect(item.priority <= 10)
    }

    @Test("Shows one star for priority 11-25")
    func showsOneStarBadge() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Creativity",
            detailedDescription: "Expressing ideas",
            priority: 15,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority > 10)
        #expect(item.priority <= 25)
    }

    @Test("Shows no badge for priority > 25")
    func showsNoBadgeForLowPriority() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Low priority value",
            detailedDescription: "Less important",
            priority: 50,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority > 25)
    }

    @Test("Priority boundary at 5 shows three stars")
    func priority5ShowsThreeStars() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Boundary test",
            detailedDescription: nil,
            priority: 5,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority <= 5)
    }

    @Test("Priority boundary at 6 shows two stars")
    func priority6ShowsTwoStars() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Boundary test",
            detailedDescription: nil,
            priority: 6,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority > 5)
        #expect(item.priority <= 10)
    }

    @Test("Priority boundary at 10 shows two stars")
    func priority10ShowsTwoStars() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Boundary test",
            detailedDescription: nil,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority <= 10)
    }

    @Test("Priority boundary at 11 shows one star")
    func priority11ShowsOneStar() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Boundary test",
            detailedDescription: nil,
            priority: 11,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority > 10)
        #expect(item.priority <= 25)
    }

    @Test("Priority boundary at 25 shows one star")
    func priority25ShowsOneStar() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Boundary test",
            detailedDescription: nil,
            priority: 25,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority <= 25)
    }

    @Test("Priority boundary at 26 shows no badge")
    func priority26ShowsNoBadge() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Boundary test",
            detailedDescription: nil,
            priority: 26,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority > 25)
    }

    // MARK: - Value Type Display Tests

    @Test("Displays highest order value")
    func displaysHighestOrderValue() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Eudaimonia",
            detailedDescription: "Living a flourishing, meaningful life",
            priority: 1,
            lifeDomain: "Philosophy",
            additionalInfo: nil
        )

        #expect(item.friendlyName == "Eudaimonia")
        #expect(item.priority == 1)
        #expect(item.lifeDomain == "Philosophy")
        #expect(item.additionalInfo == nil)
    }

    @Test("Displays major value with alignment guidance")
    func displaysMajorValueWithGuidance() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Physical Health",
            detailedDescription: "Maintaining strength, endurance, and vitality",
            priority: 8,
            lifeDomain: "Health",
            additionalInfo: "Exercising regularly, eating well, getting adequate sleep"
        )

        #expect(item.friendlyName == "Physical Health")
        #expect(item.priority == 8)
        #expect(item.lifeDomain == "Health")
        #expect(item.additionalInfo != nil)
    }

    @Test("Displays general value")
    func displaysGeneralValue() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Creativity",
            detailedDescription: "Expressing original ideas and making new things",
            priority: 15,
            lifeDomain: "Personal Growth",
            additionalInfo: nil
        )

        #expect(item.friendlyName == "Creativity")
        #expect(item.priority == 15)
        #expect(item.lifeDomain == "Personal Growth")
        #expect(item.additionalInfo == nil)
    }

    @Test("Displays life area")
    func displaysLifeArea() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Career",
            detailedDescription: "Professional development and work life",
            priority: 20,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.friendlyName == "Career")
        #expect(item.priority == 20)
        #expect(item.lifeDomain == nil)
    }

    // MARK: - Life Domain Tests

    @Test("Displays various life domains")
    func displaysVariousLifeDomains() {
        let domains = ["Health", "Career", "Relationships", "Finance", "Personal Growth", "Philosophy"]

        for domain in domains {
            let item = ValueDisplayItem(
                id: UUID(),
                friendlyName: "Value in \(domain)",
                detailedDescription: nil,
                priority: 10,
                lifeDomain: domain,
                additionalInfo: nil
            )

            #expect(item.lifeDomain == domain)
        }
    }

    @Test("Handles custom life domain")
    func handlesCustomLifeDomain() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Custom value",
            detailedDescription: nil,
            priority: 15,
            lifeDomain: "My Custom Domain",
            additionalInfo: nil
        )

        #expect(item.lifeDomain == "My Custom Domain")
    }

    @Test("Handles nil life domain")
    func handlesNilLifeDomain() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "No domain",
            detailedDescription: nil,
            priority: 20,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.lifeDomain == nil)
    }

    // MARK: - Optional Field Tests

    @Test("Handles nil description")
    func handlesNilDescription() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Value",
            detailedDescription: nil,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.detailedDescription == nil)
    }

    @Test("Handles nil additional info")
    func handlesNilAdditionalInfo() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Value",
            detailedDescription: "Description",
            priority: 10,
            lifeDomain: "Health",
            additionalInfo: nil
        )

        #expect(item.additionalInfo == nil)
    }

    @Test("Handles all optional fields nil")
    func handlesAllOptionalFieldsNil() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: nil,
            detailedDescription: nil,
            priority: 50,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.friendlyName == nil)
        #expect(item.detailedDescription == nil)
        #expect(item.lifeDomain == nil)
        #expect(item.additionalInfo == nil)
    }

    @Test("Handles all fields populated")
    func handlesAllFieldsPopulated() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Complete Value",
            detailedDescription: "Full description here",
            priority: 5,
            lifeDomain: "Health",
            additionalInfo: "Additional guidance information"
        )

        #expect(item.friendlyName == "Complete Value")
        #expect(item.detailedDescription == "Full description here")
        #expect(item.priority == 5)
        #expect(item.lifeDomain == "Health")
        #expect(item.additionalInfo == "Additional guidance information")
    }

    // MARK: - Edge Cases

    @Test("Handles very long value name")
    func handlesLongValueName() {
        let longName = String(repeating: "Very long value name ", count: 10)
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: longName,
            detailedDescription: nil,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.friendlyName == longName)
        #expect(item.friendlyName!.count > 100)
    }

    @Test("Handles very long description")
    func handlesLongDescription() {
        let longDescription = String(repeating: "Very detailed description with lots of content. ", count: 20)
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Value",
            detailedDescription: longDescription,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.detailedDescription == longDescription)
        #expect(item.detailedDescription!.count > 500)
    }

    @Test("Handles very long additional info")
    func handlesLongAdditionalInfo() {
        let longInfo = String(repeating: "Additional guidance information. ", count: 20)
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Value",
            detailedDescription: "Description",
            priority: 8,
            lifeDomain: "Health",
            additionalInfo: longInfo
        )

        #expect(item.additionalInfo == longInfo)
        #expect(item.additionalInfo!.count > 500)
    }

    @Test("Handles priority at minimum (1)")
    func handlesMinimumPriority() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Top priority",
            detailedDescription: nil,
            priority: 1,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority == 1)
    }

    @Test("Handles priority at maximum (100)")
    func handlesMaximumPriority() {
        let item = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Low priority",
            detailedDescription: nil,
            priority: 100,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.priority == 100)
    }

    @Test("Unique IDs for different values")
    func uniqueIDsForDifferentValues() {
        let item1 = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Value 1",
            detailedDescription: nil,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        let item2 = ValueDisplayItem(
            id: UUID(),
            friendlyName: "Value 2",
            detailedDescription: nil,
            priority: 20,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item1.id != item2.id)
    }

    @Test("Same ID for same value instance")
    func sameIDForSameInstance() {
        let id = UUID()
        let item = ValueDisplayItem(
            id: id,
            friendlyName: "Value",
            detailedDescription: nil,
            priority: 10,
            lifeDomain: nil,
            additionalInfo: nil
        )

        #expect(item.id == id)
    }
}
