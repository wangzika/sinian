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

    private var pushTokenCancellable: AnyCancellable?

    private init() {
        checkExistingActivity()
    }

    /// 检查当前是否已有正在运行的想念实时活动
    public func checkExistingActivity() {
        if #available(iOS 16.1, *) {
            currentActivity = Activity<MissYouAttributes>.activities.first
            isActivityActive = currentActivity != nil
        }
    }

    /// 启动灵动岛与锁屏实时活动
    @discardableResult
    public func startActivity(
        pairId: String = "LOVE-520",
        senderName: String = "另一半",
        partnerName: String = "我",
        message: String = "此刻正在强烈想你 ❤️",
        emoji: String = "❤️",
        missCount: Int = 1,
        actionType: String = "tap"
    ) -> Bool {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("[LiveActivity] 实时活动未被系统或用户允许开启")
            return false
        }

        // 如果已有正在运行的活动，则直接更新其状态
        if currentActivity != nil {
            updateActivity(
                senderName: senderName,
                partnerName: partnerName,
                message: message,
                emoji: emoji,
                missCount: missCount,
                actionType: actionType
            )
            return true
        }

        let attributes = MissYouAttributes(pairId: pairId)
        let initialContentState = MissYouAttributes.ContentState(
            senderName: senderName,
            partnerName: partnerName,
            message: message,
            emoji: emoji,
            missCount: missCount,
            actionType: actionType,
            lastSentAt: Date()
        )

        do {
            // 本地通过 WebSocket 信令驱动实时活动刷新，无需依赖远端 APNs 推送证书 (适配个人开发者签名)
            let activityPushType: PushType? = nil

            let activity = try Activity<MissYouAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: activityPushType
            )
            self.currentActivity = activity
            self.isActivityActive = true

            // 监听 APNs Push Token 更新 (真机环境)
            if activityPushType != nil {
                Task {
                    for await tokenData in activity.pushTokenUpdates {
                        let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
                        print("[LiveActivity] 灵动岛 Push Token: \(tokenString)")
                        await MainActor.run {
                            self.lastPushToken = tokenString
                        }
                        // 同步 Token 到服务端
                        SyncService.shared.registerPushToken(tokenString)
                    }
                }
            }
            print("[LiveActivity] 成功启动灵动岛实时活动 (ID: \(activity.id))")
            scheduleAutoDismiss()
            return true
        } catch {
            print("[LiveActivity] 启动实时活动失败: \(error.localizedDescription)")
            return false
        }
    }

    /// 实时刷新灵动岛内容与特效
    public func updateActivity(
        senderName: String,
        partnerName: String,
        message: String,
        emoji: String,
        missCount: Int,
        actionType: String
    ) {
        guard let activity = currentActivity else {
            // 若未启动则直接启动
            startActivity(
                senderName: senderName,
                partnerName: partnerName,
                message: message,
                emoji: emoji,
                missCount: missCount,
                actionType: actionType
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
            lastSentAt: Date()
        )

        Task {
            let alertConfig = AlertConfiguration(
                title: LocalizedStringResource(stringLiteral: "\(senderName) 想你啦！"),
                body: LocalizedStringResource(stringLiteral: message),
                sound: .default
            )
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil),
                alertConfiguration: alertConfig
            )
            await MainActor.run {
                self.scheduleAutoDismiss()
            }
        }
    }

    /// 结束实时活动
    public func endActivity() {
        dismissTask?.cancel()
        dismissTask = nil

        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            await MainActor.run {
                self.currentActivity = nil
                self.isActivityActive = false
            }
        }
    }

    private var dismissTask: Task<Void, Never>?

    /// 自动定时收起灵动岛（默认 15 秒后优雅淡出）
    private func scheduleAutoDismiss() {
        dismissTask?.cancel()
        let seconds = PairSession.shared.autoDismissSeconds
        guard seconds > 0 else { return } // 0 表示常驻，不自动退出

        dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            print("[LiveActivity] 定时达到 (\(seconds)s)，自动收起灵动岛")
            self?.endActivity()
        }
    }
}
