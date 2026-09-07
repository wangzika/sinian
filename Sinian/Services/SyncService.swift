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
    private var silentAudioPlayer: AVAudioPlayer?
    private var pingTimer: Timer?
    private var reconnectTimer: Timer?
    private var isReconnecting: Bool = false
    private var currentServerURL: String = ""
    private var currentPairCode: String = ""

    private override init() {
        super.init()
        let config = URLSessionConfiguration.default
        config.shouldUseExtendedBackgroundIdleMode = true
        config.waitsForConnectivity = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        setupAudioSession()
        startSilentAudio()
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

    /// 产生 1 秒微型静音 WAV 数据，用于后台音频保活
    private func makeSilentWavData() -> Data {
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        let totalSize: UInt32 = 36 + 8000
        withUnsafeBytes(of: totalSize) { data.append(contentsOf: $0) }
        data.append(contentsOf: "WAVEfmt ".utf8)
        let subchunk1Size: UInt32 = 16
        withUnsafeBytes(of: subchunk1Size) { data.append(contentsOf: $0) }
        let format: UInt16 = 1 // PCM
        withUnsafeBytes(of: format) { data.append(contentsOf: $0) }
        let channels: UInt16 = 1 // Mono
        withUnsafeBytes(of: channels) { data.append(contentsOf: $0) }
        let sampleRate: UInt32 = 8000
        withUnsafeBytes(of: sampleRate) { data.append(contentsOf: $0) }
        let byteRate: UInt32 = 8000 // SampleRate * Channels * BitsPerSample / 8
        withUnsafeBytes(of: byteRate) { data.append(contentsOf: $0) }
        let blockAlign: UInt16 = 1 // Channels * BitsPerSample / 8
        withUnsafeBytes(of: blockAlign) { data.append(contentsOf: $0) }
        let bitsPerSample: UInt16 = 8
        withUnsafeBytes(of: bitsPerSample) { data.append(contentsOf: $0) }
        data.append(contentsOf: "data".utf8)
        let dataSize: UInt32 = 8000
        withUnsafeBytes(of: dataSize) { data.append(contentsOf: $0) }
        data.append(Data(count: 8000)) // 8000 个 0 字节代表纯静音
        return data
    }

    /// 启动后台静音守护音频流，防止 iOS 息屏后冻结进程与断开网络
    public func startSilentAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            if silentAudioPlayer == nil {
                let silentData = makeSilentWavData()
                silentAudioPlayer = try AVAudioPlayer(data: silentData)
                silentAudioPlayer?.numberOfLoops = -1 // 无限次无缝循环
                silentAudioPlayer?.volume = 0.0 // 0 音量，绝对无声无扰
            }
            silentAudioPlayer?.play()
            print("[SyncService] 息屏防断联守护引擎已启动，已进入永久保活状态")
        } catch {
            print("[SyncService] 启动后台音频守护失败: \(error.localizedDescription)")
        }
    }

    /// 进入后台时保持长连接活跃，确保能接收到思念信号并激活灵动岛
    public func beginBackgroundExecution() {
        endBackgroundExecution()
        startSilentAudio()
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SinianWebSocketKeepAlive") { [weak self] in
            print("[SyncService] 系统即将回收后台执行时间，静音音频守护接管保活")
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
        self.currentServerURL = serverURL
        self.currentPairCode = pairCode

        var cleanURL = serverURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanURL.hasPrefix("ws://") && !cleanURL.hasPrefix("wss://") {
            cleanURL = "ws://\(cleanURL)"
        }
        guard let url = URL(string: "\(cleanURL)?pairCode=\(pairCode)") else { return }
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        startSilentAudio()

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        startPingTimer()
        listenForMessages()
    }

    /// 启动心跳 Ping 探测定时器
    private func startPingTimer() {
        stopPingTimer()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendHeartbeatPing()
            }
        }
    }

    private func stopPingTimer() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendHeartbeatPing() {
        guard isConnected, let task = webSocketTask else { return }
        task.sendPing { [weak self] error in
            if let error = error {
                print("[SyncService] WebSocket 心跳 Ping 失败: \(error.localizedDescription)，立即触发自动重连")
                Task { @MainActor [weak self] in
                    self?.handleDisconnection()
                }
            }
        }
    }

    /// 统一断线处理与自动调度重连
    public func handleDisconnection() {
        guard !isReconnecting else { return }
        isConnected = false
        partnerOnline = false
        stopPingTimer()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        scheduleAutoReconnect()
    }

    /// 自动重连引擎
    public func scheduleAutoReconnect() {
        guard !isConnected else { return }
        isReconnecting = true
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isReconnecting = false
                guard !self.isConnected else { return }
                let url = self.currentServerURL.isEmpty ? PairSession.shared.serverURL : self.currentServerURL
                let code = self.currentPairCode.isEmpty ? PairSession.shared.pairCode : self.currentPairCode
                print("[SyncService] 触发自动重连机制: \(url) [\(code)]")
                self.connect(url: url, pairCode: code)
            }
        }
    }

    public func disconnect() {
        stopPingTimer()
        reconnectTimer?.invalidate()
        reconnectTimer = nil
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
        if !LiveActivityManager.shared.isActivityActive {
            postLocalMissNotification(senderName: partnerName, message: message, emoji: emoji)
        }

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

        // 触发灵动岛与锁屏显示（未读强提醒）
        LiveActivityManager.shared.updateActivity(
            senderName: partnerName,
            partnerName: myName,
            message: message,
            emoji: emoji,
            missCount: PairSession.shared.todayMissCount,
            actionType: actionType,
            isUnread: true
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
                    self.handleDisconnection()
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
            self.partnerOnline = (roomSize >= 2)
            if roomSize >= 2 {
                PairSession.shared.isPaired = true
                LiveActivityManager.shared.ensureActivityActive(
                    pairId: PairSession.shared.pairCode,
                    partnerName: PairSession.shared.partnerNickname,
                    myName: PairSession.shared.myNickname,
                    missCount: PairSession.shared.todayMissCount
                )
            }

        case "partner_connected":
            self.partnerOnline = true
            PairSession.shared.isPaired = true
            LiveActivityManager.shared.ensureActivityActive(
                pairId: PairSession.shared.pairCode,
                partnerName: PairSession.shared.partnerNickname,
                myName: PairSession.shared.myNickname,
                missCount: PairSession.shared.todayMissCount
            )

        case "partner_disconnected":
            self.partnerOnline = false

        case "miss_you":
            let senderName = json["senderName"] as? String ?? PairSession.shared.partnerNickname
            let message = json["message"] as? String ?? "此刻正在想你 ❤️"
            let emoji = json["emoji"] as? String ?? "❤️"
            let actionType = json["actionType"] as? String ?? "tap"

            // 申请临时系统后台任务断言，避免被系统标记为“仅后台音频”
            var bgTask: UIBackgroundTaskIdentifier = .invalid
            bgTask = UIApplication.shared.beginBackgroundTask(withName: "LiveActivityMissPush") {
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = .invalid
                }
            }

            // 播放心跳震动
            HapticManager.shared.playPartnerMissNotification()

            // 总是发送本地通知，确保灵动岛下拉横幅/锁屏横幅必出强提醒
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

            // 暂时微暂停静音播放并释放音频会话，让 RunningBoard 进程断言完全切换为 background-task
            let wasAudioPlaying = self.silentAudioPlayer?.isPlaying ?? false
            if wasAudioPlaying {
                self.silentAudioPlayer?.pause()
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }

            // 启动或更新灵动岛与锁屏显示
            LiveActivityManager.shared.startActivity(
                senderName: senderName,
                partnerName: PairSession.shared.myNickname,
                message: message,
                emoji: emoji,
                missCount: PairSession.shared.todayMissCount,
                actionType: actionType,
                isUnread: true
            )

            // 600毫秒后恢复静音音频守护并释放任务断言
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                if wasAudioPlaying {
                    self?.startSilentAudio()
                }
                if bgTask != .invalid {
                    UIApplication.shared.endBackgroundTask(bgTask)
                    bgTask = .invalid
                }
            }

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
            print("[SyncService] 与信令服务器的连接已关闭 (code: \(closeCode.rawValue))，准备重连")
            SyncService.shared.handleDisconnection()
        }
    }

    nonisolated public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Task { @MainActor in
                print("[SyncService] WebSocket 任务异常中断: \(error.localizedDescription)，立即重连")
                SyncService.shared.handleDisconnection()
            }
        }
    }
}
