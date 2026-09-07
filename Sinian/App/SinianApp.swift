//
//  SinianApp.swift
//  Sinian
//

import SwiftUI

@main
struct SinianApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared

                    // 检查当前是否有正在进行的实时活动
                    liveActivityManager.checkExistingActivity()

                    // 自动配置设备服务器地址（默认连接 Render 公网云端服务）
                    if pairSession.serverURL.contains("localhost") || pairSession.serverURL.contains("127.0.0.1") || pairSession.serverURL.contains("172.20.") || pairSession.serverURL.contains("192.168.") {
                        pairSession.serverURL = "wss://sinian-server.onrender.com"
                    }

                    if pairSession.pairCode.isEmpty {
                        pairSession.pairCode = "LOVE-520"
                    }
                    pairSession.isPaired = true

                    // 启动自动连接信令服务
                    syncService.connect(url: pairSession.serverURL, pairCode: pairSession.pairCode)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:
                        // App 激活到前台
                        print("[SinianApp] 应用进入前台 (Active)")
                        if pairSession.serverURL.contains("172.20.") || pairSession.serverURL.contains("192.168.") || pairSession.serverURL.contains("localhost") {
                            pairSession.serverURL = "wss://sinian-server.onrender.com"
                        }
                        if pairSession.isPaired && !pairSession.pairCode.isEmpty && !syncService.isConnected {
                            print("[SinianApp] 自动建立信令长连接: \(pairSession.serverURL) [\(pairSession.pairCode)]")
                            syncService.connect(url: pairSession.serverURL, pairCode: pairSession.pairCode)
                        }
                        liveActivityManager.ensureActivityActive(
                            pairId: pairSession.pairCode,
                            partnerName: pairSession.partnerNickname,
                            myName: pairSession.myNickname,
                            missCount: pairSession.todayMissCount
                        )
                    case .background:
                        // 用户上滑退出/回到桌面
                        print("[SinianApp] 应用退入后台 (桌面)")
                        syncService.beginBackgroundExecution()
                        if liveActivityManager.shouldDismissOnAppExit {
                            print("[SinianApp] 用户已查看消息并退出应用，收起灵动岛为隐形待命")
                            liveActivityManager.setActivityToIdle(
                                partnerName: pairSession.partnerNickname,
                                myName: pairSession.myNickname,
                                missCount: pairSession.todayMissCount
                            )
                        }
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
                .onOpenURL { url in
                    print("[SinianApp] 收到 URL 协议调用: \(url.absoluteString)")
                    if url.host == "open_message" {
                        liveActivityManager.markMessageAsViewed()
                        pairSession.hasUnreadReceivedMessage = true
                    } else if url.host == "reply" {
                        syncService.sendMiss(message: "我也好想你 ❤️", emoji: "❤️", actionType: "tap")
                        liveActivityManager.setActivityToIdle(
                            partnerName: pairSession.partnerNickname,
                            myName: pairSession.myNickname,
                            missCount: pairSession.todayMissCount
                        )
                    } else if url.host == "dismiss" {
                        print("[SinianApp] 用户点击我知道啦，收起灵动岛为隐形待命")
                        liveActivityManager.setActivityToIdle(
                            partnerName: pairSession.partnerNickname,
                            myName: pairSession.myNickname,
                            missCount: pairSession.todayMissCount
                        )
                    } else if url.host == "simulate" {
                        syncService.simulatePartnerMiss()
                    } else if url.host == "start" {
                        liveActivityManager.startActivity(
                            senderName: pairSession.partnerNickname,
                            partnerName: pairSession.myNickname,
                            message: "此刻正在强烈想你 ❤️",
                            emoji: "❤️",
                            missCount: pairSession.todayMissCount,
                            isUnread: true
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

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            PairSession.shared.hasUnreadReceivedMessage = true
            LiveActivityManager.shared.markMessageAsViewed()
        }
        completionHandler()
    }
}
