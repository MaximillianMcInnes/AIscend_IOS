//
//  AIscendChatLogicTests.swift
//  AIscendTests
//
//  Created by Codex on 4/8/26.
//

import Foundation
import Testing
@testable import AIscend

struct AIscendChatLogicTests {

    @Test func titleBuilderCollapsesWhitespaceAndTruncatesGracefully() {
        let title = AIscendChatTitleBuilder.title(
            from: "   I need   a cleaner weekly strategy for fitness, presentation, and work focus   "
        )

        #expect(title == "I need a cleaner weekly strategy for fitness,…")
    }

    @Test func groupingPlacesThreadsIntoExpectedSections() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        let now = Date(timeIntervalSince1970: 1_744_113_600) // 2025-04-12 00:00:00 UTC
        let today = makeThread(id: "today", daysAgo: 0, calendar: calendar, now: now)
        let yesterday = makeThread(id: "yesterday", daysAgo: 1, calendar: calendar, now: now)
        let thisWeek = makeThread(id: "week", daysAgo: 4, calendar: calendar, now: now)
        let previous = makeThread(id: "previous", daysAgo: 10, calendar: calendar, now: now)

        let sections = AIscendChatGrouping.sections(
            from: [previous, thisWeek, yesterday, today],
            now: now,
            calendar: calendar
        )

        #expect(sections.map(\.key) == [.today, .yesterday, .thisWeek, .previous])
        #expect(sections.first?.threads.first?.id == "today")
        #expect(sections[1].threads.first?.id == "yesterday")
        #expect(sections[2].threads.first?.id == "week")
        #expect(sections[3].threads.first?.id == "previous")
    }

    @Test func workspaceStateTreatsExistingHistoryAsRecoveryInsteadOfEmpty() {
        let historyThread = AIscendChatThread(
            id: "history",
            email: "user@example.com",
            title: "Saved chat",
            messages: [.user("Review my last routine.")],
            updatedAt: .now,
            createdAt: .now
        )

        let state = AIscendChatWorkspaceState.resolve(
            isAuthenticated: true,
            isBootstrapping: false,
            threads: [historyThread],
            messages: [],
            prefersFreshConversation: false
        )

        #expect(state == .recovery)
    }

    @Test func workspaceStatePrefersDraftWhenFreshConversationIsRequested() {
        let historyThread = AIscendChatThread(
            id: "history",
            email: "user@example.com",
            title: "Saved chat",
            messages: [.user("Review my last routine.")],
            updatedAt: .now,
            createdAt: .now
        )

        let state = AIscendChatWorkspaceState.resolve(
            isAuthenticated: true,
            isBootstrapping: true,
            threads: [historyThread],
            messages: [],
            prefersFreshConversation: true
        )

        #expect(state == .draft)
    }

    @Test func chatIdentityFallsBackToSyntheticEmailForUidOnlySessions() {
        let identity = AIscendChatIdentity(userID: "user-123", email: nil)

        #expect(identity?.requestEmail == "user-123@private.aiscend.local")
    }

    private func makeThread(id: String, daysAgo: Int, calendar: Calendar, now: Date) -> AIscendChatThread {
        let updatedAt = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now

        return AIscendChatThread(
            id: id,
            email: "user@example.com",
            title: "Conversation \(id)",
            messages: [.user("Message \(id)")],
            updatedAt: updatedAt,
            createdAt: updatedAt
        )
    }
}
