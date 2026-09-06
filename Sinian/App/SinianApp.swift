//
//  SinianApp.swift
//  Sinian
//

import SwiftUI

@main
struct SinianApp: App {
    @StateObject private var pairSession = PairSession.shared
    @StateObject private var liveActivityManager = LiveActivityManager.shared
    @StateObject private var syncService = SyncService.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(pairSession)
                .environmentObject(liveActivityManager)
                .environmentObject(syncService)
                .onAppear {
                    // 检查当前是否有正在进行的实时活动
                    liveActivityManager.checkExistingActivity()

                    // 自动检查并升级真实设备的服务器地址为当前局域网 IP
                    #if !targetEnvironment(simulator)
                    if pairSession.serverURL.contains("localhost") || pairSession.serverURL.contains("127.0.0.1") {
                        pairSession.serverURL = "ws://172.20.10.12:8080"
                    }
                    #endif

                    if pairSession.pairCode.isEmpty {
                        pairSession.pairCode = "LOVE-520"
                    }
                    pairSession.isPaired = true

                    // 启动自动连接信令服务
                    syncService.connect(url: pairSession.serverURL, pairCode: pairSession.pairCode)
                }
                .onOpenURL { url in
                    print("[SinianApp] 收到 URL 协议调用: \(url.absoluteString)")
                    if url.host == "reply" {
                        syncService.sendMiss(message: "我也好想你 ❤️", emoji: "❤️", actionType: "tap")
                    } else if url.host == "dismiss" {
                        liveActivityManager.endActivity()
                    } else if url.host == "simulate" {
                        syncService.simulatePartnerMiss()
                    } else if url.host == "start" {
                        liveActivityManager.startActivity(
                            senderName: pairSession.partnerNickname,
                            partnerName: pairSession.myNickname,
                            message: "此刻正在强烈想你 ❤️",
                            emoji: "❤️",
                            missCount: pairSession.todayMissCount
                        )
                    } else if url.host == "pair" {
                        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                        let code = components?.queryItems?.first(where: { $0.name == "code" })?.value ?? "LOVE-520"
                        pairSession.pairCode = code
                        pairSession.isPaired = true
                        syncService.connect(url: pairSession.serverURL, pairCode: code)
                    }
                }
        }
    }
}
