//
//  LiveActivityManager.swift
//  Sinian
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

@MainActor
public final class LiveActivityManager: ObservableObject {
    public static let shared = LiveActivityManager()

    @Published public private(set) var currentActivity: Activity<MissYouAttributes>?
    @Published public var isActivityActive: Bool = false
    @Published public var lastPushToken: String?
    
    /// 是否在退出 App 时收起灵动岛（当用户在 App 中查看过消息后置为 true）
    @Published public var shouldDismissOnAppExit: Bool = false
    @Published public var lastReceivedMessage: String = ""
    @Published public var lastSenderName: String = ""
    @Published public var lastEmoji: String = "❤️"

    private var pushTokenCancellable: AnyCancellable?

    private init() {
        checkExistingActivity()
    }

    /// 标记用户已在 App 内看到最新消息
    public func markMessageAsViewed() {
        guard isActivityActive else { return }
        shouldDismissOnAppExit = true
        print("[LiveActivity] 消息已在 App 内被查看，已标记退出时自动收起灵动岛")
    }

    /// 重置已读状态（当收到新消息时）
    public func clearViewedState() {
        shouldDismissOnAppExit = false
    }

    /// 检查当前是否已有正在运行的想念实时活动
    public func checkExistingActivity() {
        if #available(iOS 16.1, *) {
            for act in Activity<MissYouAttributes>.activities {
                print("[LiveActivity] 系统中活动 ID: \(act.id), 状态: \(act.activityState)")
            }
            // 严格只认当前处于 active 活跃状态的实时活动
            currentActivity = Activity<MissYouAttributes>.activities.first(where: { $0.activityState == .active })
            isActivityActive = (currentActivity != nil)
            print("[LiveActivity] 检查结果 -> 当前活跃活动: \(currentActivity?.id ?? "无") (isActivityActive: \(isActivityActive))")
        }
    }

    /// 启动灵动岛与锁屏实时活动（常驻挂在灵动岛，不设自动超时）
    @discardableResult
    public func startActivity(
        pairId: String = "LOVE-520",
        senderName: String = "另一半",
        partnerName: String = "我",
        message: String = "此刻正在强烈想你 ❤️",
        emoji: String = "❤️",
        missCount: Int = 1,
        actionType: String = "tap",
        isUnread: Bool = true
    ) -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] 实时活动未被系统或用户允许开启 (areActivitiesEnabled: false)")
            return false
        }

        self.lastReceivedMessage = message
        self.lastSenderName = senderName
        self.lastEmoji = emoji
        self.shouldDismissOnAppExit = false

        // 如果已有正在运行且处于 active 状态的活动，则直接更新其状态
        if let activity = currentActivity, activity.activityState == .active {
            print("[LiveActivity] 发现已有活跃活动 \(activity.id)，直接进行内容更新")
            updateActivity(
                senderName: senderName,
                partnerName: partnerName,
                message: message,
                emoji: emoji,
                missCount: missCount,
                actionType: actionType,
                isUnread: isUnread
            )
            return true
        }

        currentActivity = nil
        isActivityActive = false

        let attributes = MissYouAttributes(pairId: pairId)
        let initialContentState = MissYouAttributes.ContentState(
            senderName: senderName,
            partnerName: partnerName,
            message: message,
            emoji: emoji,
            missCount: missCount,
            actionType: actionType,
            lastSentAt: Date(),
            isUnread: isUnread
        )

        do {
            let activityPushType: PushType? = nil

            let activity = try Activity<MissYouAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: activityPushType
            )
            self.currentActivity = activity
            self.isActivityActive = true

            if activityPushType != nil {
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
                        print("[LiveActivity] 灵动岛 Push Token: \(tokenString)")
                        await MainActor.run {
                            self.lastPushToken = tokenString
                        }
                        SyncService.shared.registerPushToken(tokenString)
                    }
                }
            }
            print("[LiveActivity] 成功启动灵动岛实时活动 (ID: \(activity.id), isUnread: \(isUnread))")
            return true
        } catch {
            print("[LiveActivity] 启动实时活动失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 确保灵动岛在前台已就绪待命（前台自动初始化，避免后台无法创建）
    public func ensureActivityActive(
        pairId: String = "LOVE-520",
        partnerName: String = "另一半",
        myName: String = "我",
        missCount: Int = 0
    ) {
        checkExistingActivity()
        if let current = currentActivity, current.activityState == .active {
            print("[LiveActivity] 灵动岛已存在活跃心跳连线: \(current.id)")
            return
        }
        print("[LiveActivity] 前台无活跃灵动岛连线，立即自动创建")
        startActivity(
            pairId: pairId,
            senderName: partnerName,
            partnerName: myName,
            message: "心跳连线中",
            emoji: "❤️",
            missCount: missCount,
            actionType: "idle",
            isUnread: false
        )
    }

    /// 实时刷新灵动岛内容与强提醒动画
    public func updateActivity(
        senderName: String,
        partnerName: String,
        message: String,
        emoji: String,
        missCount: Int,
        actionType: String,
        isUnread: Bool = true
    ) {
        self.lastReceivedMessage = message
        self.lastSenderName = senderName
        self.lastEmoji = emoji
        self.shouldDismissOnAppExit = false

        guard let activity = currentActivity, activity.activityState == .active else {
            print("[LiveActivity] updateActivity 发现当前无活跃活动，转为调用 startActivity")
            startActivity(
                senderName: senderName,
                partnerName: partnerName,
                message: message,
                emoji: emoji,
                missCount: missCount,
                actionType: actionType,
                isUnread: isUnread
            )
            return
        }

        let updatedState = MissYouAttributes.ContentState(
            senderName: senderName,
            partnerName: partnerName,
            message: message,
            emoji: emoji,
            missCount: missCount,
            actionType: actionType,
            lastSentAt: Date(),
            isUnread: isUnread
        )

        Task {
            var bgTask: UIBackgroundTaskIdentifier = .invalid
            bgTask = UIApplication.shared.beginBackgroundTask(withName: "ActivityKitLocalUpdate") {
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = .invalid
                }
            }
            var alertConfig: AlertConfiguration? = nil
            if isUnread {
                alertConfig = AlertConfiguration(
                    title: LocalizedStringResource(stringLiteral: "\(senderName) 想你啦！"),
                    body: LocalizedStringResource(stringLiteral: message),
                    sound: .default
                )
            }
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil),
                alertConfiguration: alertConfig
            )
            print("[LiveActivity] 成功后台更新灵动岛 (isUnread: \(isUnread))")
            if bgTask != .invalid {
                UIApplication.shared.endBackgroundTask(bgTask)
                bgTask = .invalid
            }
        }
    }

    /// 用户在 App 内查阅完后退出，消除灵动岛上的未读“想你啦”提醒，恢复为静默待命状态
    public func setActivityToIdle(
        partnerName: String,
        myName: String,
        missCount: Int
    ) {
        guard let activity = currentActivity else { return }
        self.shouldDismissOnAppExit = false

        let idleState = MissYouAttributes.ContentState(
            senderName: partnerName,
            partnerName: myName,
            message: "心跳连线中",
            emoji: "❤️",
            missCount: missCount,
            actionType: "idle",
            lastSentAt: Date(),
            isUnread: false
        )

        Task {
            await activity.update(ActivityContent(state: idleState, staleDate: nil))
            print("[LiveActivity] 灵动岛思念提醒已消除，恢复为静默连线待命")
        }
    }

    /// 结束实时活动（完全清除灵动岛，不留下任何胶囊）
    public func endActivity() {
        Task {
            for act in Activity<MissYouAttributes>.activities {
                await act.end(nil, dismissalPolicy: .immediate)
            }
            await MainActor.run {
                self.currentActivity = nil
                self.isActivityActive = false
                self.shouldDismissOnAppExit = false
                print("[LiveActivity] 灵动岛提醒已完全注销清除")
            }
        }
    }
}
