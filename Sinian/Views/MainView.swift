//
//  MainView.swift
//  Sinian
//

import SwiftUI

public struct MainView: View {
    @ObservedObject var pairSession = PairSession.shared
    @ObservedObject var syncService = SyncService.shared
    @ObservedObject var activityManager = LiveActivityManager.shared

    @State private var showingPairingSheet = false
    @State private var showingTimelineSheet = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var toastMessage: String?
    @State private var selectedPreset = "此刻正在强烈想你 ❤️"
    @State private var showingMessageModal = false
    @State private var activeMessageEvent: MissEvent?

    private let quickPhrases = [
        "此刻正在强烈想你 ❤️",
        "在干嘛呢，好想你呀 🥰",
        "隔空给你一个大大的抱抱 🫂",
        "啵啵一个 💋",
        "好想马上见到你 ✨"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.94, blue: 0.96),
                        Color(red: 0.97, green: 0.96, blue: 0.99),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 顶部情侣状态栏
                        headerBar

                        // 如果收到对方的思念，在界面顶部常驻展示醒目卡片
                        if let event = pairSession.latestReceivedEvent, !event.isFromMe {
                            receivedMessageBanner(event: event)
                                .padding(.horizontal, 16)
                                .padding(.top, -8)
                        }

                        // 未双人联机时的状态引导
                        if !syncService.partnerOnline {
                            Button(action: { showingPairingSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: syncService.isConnected ? "hourglass" : "antenna.radiowaves.left.and.right")
                                        .font(.system(size: 12))
                                    Text(syncService.isConnected ? "信令已连上 [\(pairSession.pairCode)]，等待伴侣加入..." : "未连接伴侣，点击上方头像开启双人联机")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(syncService.isConnected ? .orange : .pink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(syncService.isConnected ? Color.orange.opacity(0.12) : Color.pink.opacity(0.12))
                                )
                            }
                            .padding(.top, -14)
                        }

                        // 主交互区域：心跳想念按钮
                        VStack(spacing: 12) {
                            Text("轻触发送心跳，长按蓄力超级想念")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            HeartbeatButton(
                                onShortTap: { emoji in
                                    sendMissAction(emoji: emoji, isSuper: false)
                                },
                                onLongPressEnd: { emoji in
                                    sendMissAction(emoji: emoji, isSuper: true)
                                }
                            )
                            .padding(.vertical, 10)
                        }

                        // 快捷短语选择
                        quickPhraseSection

                        // 灵动岛控制与体验卡片
                        IslandSimulatorCard()
                            .padding(.horizontal, 16)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }

                // 顶部 Toast 提示浮窗
                if let toast = toastMessage {
                    VStack {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text(toast)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.12), radius: 10, y: 5)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .padding(.top, 16)
                    .zIndex(100)
                }

                // 核心：点开灵动岛进入 App 时弹出的思念专属卡片
                if showingMessageModal, let event = activeMessageEvent {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingMessageModal = false
                                pairSession.hasUnreadReceivedMessage = false
                            }
                        }

                    messageModalView(event: event)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .zIndex(200)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPairingSheet) {
                PairingView()
            }
            .sheet(isPresented: $showingTimelineSheet) {
                MemoryTimelineView()
            }
            .onAppear {
                checkAndPresentUnreadMessage()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    checkAndPresentUnreadMessage()
                }
            }
            .onChange(of: pairSession.hasUnreadReceivedMessage) { _, hasUnread in
                if hasUnread {
                    checkAndPresentUnreadMessage()
                }
            }
        }
    }

    /// 检查未读消息并在 App 处于前台活跃时弹出展示
    private func checkAndPresentUnreadMessage() {
        guard scenePhase == .active else { return }
        if let event = pairSession.latestReceivedEvent, !event.isFromMe, pairSession.hasUnreadReceivedMessage {
            activeMessageEvent = event
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showingMessageModal = true
            }
            HapticManager.shared.playHeartbeat()
        }
    }

    private var headerBar: some View {
        HStack {
            // 情侣双方头像与连接状态
            Button(action: { showingPairingSheet = true }) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Text(String(pairSession.partnerNickname.prefix(1)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.pink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(pairSession.partnerNickname)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 5) {
                            if syncService.partnerOnline {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("伴侣在线")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)
                            } else if syncService.isConnected {
                                Circle().fill(Color.orange).frame(width: 6, height: 6)
                                Text("等待对方")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                            } else {
                                Circle().fill(Color.gray).frame(width: 6, height: 6)
                                Text("单机模式")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
                )
            }

            Spacer()

            // 足迹入口
            Button(action: { showingTimelineSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                    Text("\(pairSession.todayMissCount)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(.pink)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.pink.opacity(0.12))
                )
            }
        }
        .padding(.horizontal, 18)
    }

    private var quickPhraseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("想念寄语")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(quickPhrases, id: \.self) { phrase in
                        Button(action: {
                            selectedPreset = phrase
                            HapticManager.shared.playTap()
                        }) {
                            Text(phrase)
                                .font(.system(size: 13, weight: selectedPreset == phrase ? .semibold : .regular))
                                .foregroundColor(selectedPreset == phrase ? .white : .primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedPreset == phrase ? Color.pink : Color.white.opacity(0.85))
                                        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
                                )
                        }
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private func sendMissAction(emoji: String, isSuper: Bool) {
        let msg = isSuper ? "【超级想念】\(selectedPreset)" : selectedPreset
        let action = isSuper ? "super_miss" : "tap"

        SyncService.shared.sendMiss(message: msg, emoji: emoji, actionType: action)

        if syncService.partnerOnline {
            showToast(isSuper ? "已向 \(pairSession.partnerNickname) 发送超级想念 🌟" : "心跳已跨屏送达 ❤️")
        } else if syncService.isConnected {
            showToast("已发送至中转，等待伴侣连接... ⏳")
        } else {
            showToast("心跳已记录（当前处于单机模式）❤️")
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                if toastMessage == message {
                    toastMessage = nil
                }
            }
        }
    }

    /// 伴侣最新思念提示卡片
    private func receivedMessageBanner(event: MissEvent) -> some View {
        Button(action: {
            activeMessageEvent = event
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                showingMessageModal = true
            }
            activityManager.markMessageAsViewed()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text(event.emoji)
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("\(event.senderName) 的思念")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.pink)
                        Spacer()
                        Text(event.timestamp, style: .time)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Text(event.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.92))
                    .shadow(color: Color.pink.opacity(0.12), radius: 8, x: 0, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    /// 点开灵动岛进入 App 时弹出的浪漫想念卡片
    private func messageModalView(event: MissEvent) -> some View {
        VStack(spacing: 20) {
            // 顶部爱心光晕与表情
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pink.opacity(0.35), Color.pink.opacity(0.05)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 90, height: 90)

                Text(event.emoji)
                    .font(.system(size: 46))
            }
            .padding(.top, 8)

            // 发送者与时间
            VStack(spacing: 4) {
                Text("\(event.senderName) 想你啦！")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(event.timestamp, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // 寄语内容展示框
            VStack(spacing: 8) {
                Text("“\(event.message)”")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.pink.opacity(0.08))
                    )
            }

            // 操作按钮组
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingMessageModal = false
                        pairSession.hasUnreadReceivedMessage = false
                    }
                    activityManager.markMessageAsViewed()
                    activityManager.setActivityToIdle(
                        partnerName: pairSession.partnerNickname,
                        myName: pairSession.myNickname,
                        missCount: pairSession.todayMissCount
                    )
                }) {
                    Text("我知道啦")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                }

                Button(action: {
                    sendMissAction(emoji: "❤️", isSuper: false)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingMessageModal = false
                        pairSession.hasUnreadReceivedMessage = false
                    }
                    activityManager.markMessageAsViewed()
                    activityManager.setActivityToIdle(
                        partnerName: pairSession.partnerNickname,
                        myName: pairSession.myNickname,
                        missCount: pairSession.todayMissCount
                    )
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                        Text("我也想你")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 10)
        )
    }
}
