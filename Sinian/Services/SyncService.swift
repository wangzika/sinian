//
//  SyncService.swift
//  Sinian
//

import Foundation
import Combine
import SwiftUI
import ActivityKit
import UIKit
import AVFoundation
import UserNotifications

@MainActor
public final class SyncService: NSObject, ObservableObject {
    public static let shared = SyncService()

    @Published public var isConnected: Bool = false
    @Published public var partnerOnline: Bool = false
    @Published public var lastReceivedEvent: MissEvent?

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.shouldUseExtendedBackgroundIdleMode = true
        config.waitsForConnectivity = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        setupAudioSession()
        requestNotificationPermission()
    }

    /// 请求系统通知权限（用于锁屏与灵动岛顶部弹窗）
    public func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("[SyncService] 系统通知权限: \(granted ? "已允许" : "未允许")")
        }
    }

    /// 发送本地灵动岛下拉通知
    public func postLocalMissNotification(senderName: String, message: String, emoji: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(senderName) 想你啦！\(emoji)"
        content.body = message
        content.sound = .default
        content.userInfo = ["url": "sinian://open_message"]

        let request = UNNotificationRequest(
            identifier: "sinian_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[SyncService] 发送本地通知失败: \(error.localizedDescription)")
            } else {
                print("[SyncService] 成功触发系统通知/灵动岛下拉横幅")
            }
        }
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SyncService] 音频会话配置提示: \(error.localizedDescription)")
        }
    }

    /// 进入后台时保持长连接活跃，确保能接收到思念信号并激活灵动岛
    public func beginBackgroundExecution() {
        endBackgroundExecution()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SinianWebSocketKeepAlive") { [weak self] in
            print("[SyncService] 系统即将回收后台执行时间")
            self?.endBackgroundExecution()
        }
        print("[SyncService] 开启后台网络保持任务 (ID: \(backgroundTaskID.rawValue))")
    }

    public func endBackgroundExecution() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }

    /// 连接配对信令服务器
    public func connect(url serverURL: String, pairCode: String) {
        var cleanURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.hasPrefix("ws://") && !cleanURL.hasPrefix("wss://") {
            cleanURL = "ws://\(cleanURL)"
        }
        guard let url = URL(string: "\(cleanURL)?pairCode=\(pairCode)") else { return }
        disconnect()

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        listenForMessages()
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        partnerOnline = false
    }

    /// 向另一半发送想念事件
    public func sendMiss(
        message: String = "此刻正在强烈想你 ❤️",
        emoji: String = "❤️",
        actionType: String = "tap"
    ) {
        let pairSession = PairSession.shared
        let myName = pairSession.myNickname
        let partnerName = pairSession.partnerNickname

        // 1. 本地记录
        let event = MissEvent(
            senderName: myName,
            isFromMe: true,
            message: message,
            emoji: emoji,
            actionType: actionType
        )
        pairSession.recordEvent(event)

        // 2. 发送给信令服务器 (仅接收方会弹出灵动岛提醒)
        let payload: [String: Any] = [
            "type": "miss_you",
            "pairCode": pairSession.pairCode,
            "senderName": myName,
            "message": message,
            "emoji": emoji,
            "actionType": actionType,
            "timestamp": Date().timeIntervalSince1970
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(wsMessage) { error in
                if let error = error {
                    print("[SyncService] 发送消息失败: \(error.localizedDescription)")
                }
            }
        }
    }

    /// 上报本机的 Live Activity Push Token
    public func registerPushToken(_ token: String) {
        let payload: [String: Any] = [
            "type": "register_push_token",
            "pairCode": PairSession.shared.pairCode,
            "pushToken": token
        ]
        if let data = try? JSONSerialization.data(withJSONObject: payload),
           let jsonString = String(data: data, encoding: .utf8) {
            let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
            webSocketTask?.send(wsMessage) { _ in }
        }
    }

    /// 模拟收到对方的想念（用于单机调试或离线体验灵动岛特效）
    public func simulatePartnerMiss(
        message: String = "宝贝，突然超级想你！🥰",
        emoji: String = "🥰",
        actionType: String = "super_miss"
    ) {
        let partnerName = PairSession.shared.partnerNickname
        let myName = PairSession.shared.myNickname

        // 触发触觉与震动
        HapticManager.shared.playPartnerMissNotification()
        postLocalMissNotification(senderName: partnerName, message: message, emoji: emoji)

        // 记录到足迹与未读思念
        let event = MissEvent(
            senderName: partnerName,
            isFromMe: false,
            message: message,
            emoji: emoji,
            actionType: actionType
        )
        PairSession.shared.recordEvent(event)
        PairSession.shared.latestReceivedEvent = event
        PairSession.shared.hasUnreadReceivedMessage = true

        // 触发灵动岛与锁屏显示
        LiveActivityManager.shared.startActivity(
            senderName: partnerName,
            partnerName: myName,
            message: message,
            emoji: emoji,
            missCount: PairSession.shared.todayMissCount,
            actionType: actionType
        )
    }

    private func listenForMessages() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleIncomingText(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleIncomingText(text)
                        }
                    @unknown default:
                        break
                    }
                    self.listenForMessages() // 继续监听下一个消息
                case .failure(let error):
                    print("[SyncService] 接收消息失败: \(error.localizedDescription)")
                    self.isConnected = false
                }
            }
        }
    }

    private func handleIncomingText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "room_status":
            let roomSize = json["roomSize"] as? Int ?? 1
            self.partnerOnline = roomSize >= 2
            if roomSize >= 2 {
                PairSession.shared.isPaired = true
            }

        case "partner_connected":
            self.partnerOnline = true
            PairSession.shared.isPaired = true

        case "partner_disconnected":
            self.partnerOnline = false

        case "miss_you":
            let senderName = json["senderName"] as? String ?? PairSession.shared.partnerNickname
            let message = json["message"] as? String ?? "此刻正在想你 ❤️"
            let emoji = json["emoji"] as? String ?? "❤️"
            let actionType = json["actionType"] as? String ?? "tap"

            // 播放震动与灵动岛下拉横幅通知
            HapticManager.shared.playPartnerMissNotification()
            postLocalMissNotification(senderName: senderName, message: message, emoji: emoji)

            // 记录事件并更新最新未读思念
            let event = MissEvent(
                senderName: senderName,
                isFromMe: false,
                message: message,
                emoji: emoji,
                actionType: actionType
            )
            PairSession.shared.recordEvent(event)
            PairSession.shared.latestReceivedEvent = event
            PairSession.shared.hasUnreadReceivedMessage = true

            // 激活/更新灵动岛与锁屏实时活动
            LiveActivityManager.shared.startActivity(
                senderName: senderName,
                partnerName: PairSession.shared.myNickname,
                message: message,
                emoji: emoji,
                missCount: PairSession.shared.todayMissCount,
                actionType: actionType
            )

        default:
            break
        }
    }
}

extension SyncService: URLSessionWebSocketDelegate {
    nonisolated public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            SyncService.shared.isConnected = true
            print("[SyncService] 已成功连接到信令服务器")
        }
    }

    nonisolated public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            SyncService.shared.isConnected = false
            SyncService.shared.partnerOnline = false
            print("[SyncService] 与信令服务器的连接已关闭")
        }
    }
}
