//
//  MissEvent.swift
//  Sinian
//

import Foundation

public struct MissEvent: Identifiable, Codable, Equatable {
    public var id: UUID
    public var senderName: String
    public var isFromMe: Bool
    public var message: String
    public var emoji: String
    public var timestamp: Date
    public var actionType: String // "tap", "super_miss", "hug", "kiss"

    public init(
        id: UUID = UUID(),
        senderName: String,
        isFromMe: Bool,
        message: String,
        emoji: String = "❤️",
        timestamp: Date = Date(),
        actionType: String = "tap"
    ) {
        self.id = id
        self.senderName = senderName
        self.isFromMe = isFromMe
        self.message = message
        self.emoji = emoji
        self.timestamp = timestamp
        self.actionType = actionType
    }
}
