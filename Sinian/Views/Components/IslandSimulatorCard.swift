//
//  IslandSimulatorCard.swift
//  Sinian
//

import SwiftUI

public struct IslandSimulatorCard: View {
    @ObservedObject var activityManager = LiveActivityManager.shared
    @ObservedObject var pairSession = PairSession.shared

    @State private var customMessage: String = "想抱抱你～在忙什么呀？"
    @State private var showingPreviewAlert = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 标题行
            HStack {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundColor(.pink)
                Text("灵动岛体验与调试")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(activityManager.isActivityActive ? Color.green : Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text(activityManager.isActivityActive ? "灵动岛已激活" : "未开启")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }

            // 灵动岛预览图形（模拟真实 iPhone 灵动岛药丸）
            ZStack {
                Capsule()
                    .fill(Color.black)
                    .frame(height: 38)
                    .shadow(color: .pink.opacity(0.15), radius: 8, y: 3)

                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                            .font(.system(size: 12))
                        Text(pairSession.partnerNickname)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 12)

                    Spacer()

                    Text("想你啦 ❤️")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.pink)
                        .padding(.trailing, 12)
                }
            }
            .padding(.vertical, 4)

            // 操作按钮组
            HStack(spacing: 10) {
                // 模拟对方发来想念
                Button(action: {
                    SyncService.shared.simulatePartnerMiss(
                        message: customMessage,
                        emoji: "🥰",
                        actionType: "super_miss"
                    )
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                        Text("模拟对方想念")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }

                // 启动 / 结束灵动岛
                Button(action: {
                    if activityManager.isActivityActive {
                        activityManager.endActivity()
                    } else {
                        activityManager.startActivity(
                            senderName: pairSession.partnerNickname,
                            partnerName: pairSession.myNickname,
                            message: "此刻正在强烈想你 ❤️",
                            emoji: "❤️",
                            missCount: pairSession.todayMissCount
                        )
                    }
                }) {
                    Text(activityManager.isActivityActive ? "立即关闭灵动岛" : "手动唤起灵动岛")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(activityManager.isActivityActive ? .red : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }

            // 灵动岛停留时长设置
            VStack(alignment: .leading, spacing: 6) {
                Text("想念灵动岛停留模式")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Picker("停留模式", selection: $pairSession.autoDismissSeconds) {
                    Text("15秒自动收起").tag(15)
                    Text("30秒自动收起").tag(30)
                    Text("常驻陪伴 (不消失)").tag(0)
                }
                .pickerStyle(.segmented)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}
