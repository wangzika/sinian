//
//  MissYouAttributes.swift
//  Sinian
//
//  Shared between Sinian App and SinianIslandWidget extension.
//

import Foundation
import ActivityKit

public struct MissYouAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var senderName: String         // 发送方昵称（如 "宝贝"）
        public var partnerName: String        // 接收方昵称（如 "小懒猪"）
        public var message: String            // 想念留言
        public var emoji: String              // 情绪表情
        public var missCount: Int             // 今日累计想念次数
        public var actionType: String         // 互动类型: "tap", "super_miss", "hug", "kiss"
        public var lastSentAt: Date           // 发送时间
        public var isUnread: Bool             // 是否处于未读思念提醒状态

        public init(
            senderName: String = "另一半",
            partnerName: String = "我",
            message: String = "此刻正在强烈想你 ❤️",
            emoji: String = "❤️",
            missCount: Int = 1,
            actionType: String = "tap",
            lastSentAt: Date = Date(),
            isUnread: Bool = true
        ) {
            self.senderName = senderName
            self.partnerName = partnerName
            self.message = message
            self.emoji = emoji
            self.missCount = missCount
            self.actionType = actionType
            self.lastSentAt = lastSentAt
            self.isUnread = isUnread
        }
    }

    // 静态配置项
    public var pairId: String                 // 配对会话 ID
    public var startedAt: Date                // 实时活动开启时间

    public init(pairId: String = "LOVE-520", startedAt: Date = Date()) {
        self.pairId = pairId
        self.startedAt = startedAt
    }
}
