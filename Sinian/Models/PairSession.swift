//
//  PairSession.swift
//  Sinian
//

import Foundation
import SwiftUI
import Combine

public final class PairSession: ObservableObject {
    @AppStorage("myNickname") public var myNickname: String = "宝贝"
    @AppStorage("partnerNickname") public var partnerNickname: String = "猪猪"
    @AppStorage("pairCode") public var pairCode: String = "LOVE-520"
    @AppStorage("isPaired") public var isPaired: Bool = true
    @AppStorage("serverURL") public var serverURL: String = "wss://sinian-server.onrender.com"
    @AppStorage("autoDismissSeconds") public var autoDismissSeconds: Int = 15

    @Published public var isConnectedToServer: Bool = false
    @Published public var todayMissCount: Int = 0
    @Published public var historyEvents: [MissEvent] = []
    
    /// 对方发来的最新思念消息（用于点开灵动岛进入 App 时高亮展示）
    @Published public var latestReceivedEvent: MissEvent?
    @Published public var hasUnreadReceivedMessage: Bool = false

    public static let shared = PairSession()

    private init() {
        loadHistory()
        // 自动迁移旧局域网地址到公网云端服务 (Render)
        if serverURL.contains("192.168.") || serverURL.contains("172.20.") || serverURL.contains("localhost") || serverURL.contains("127.0.0.1") {
            serverURL = "wss://sinian-server.onrender.com"
        }
    }

    public func recordEvent(_ event: MissEvent) {
        historyEvents.insert(event, at: 0)
        todayMissCount += 1
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(historyEvents) {
            UserDefaults.standard.set(data, forKey: "historyEvents")
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "historyEvents"),
           let decoded = try? JSONDecoder().decode([MissEvent].self, from: data) {
            self.historyEvents = decoded
            // 计算今天的记录数
            let calendar = Calendar.current
            self.todayMissCount = decoded.filter { calendar.isDateInToday($0.timestamp) }.count
        }
    }
}
