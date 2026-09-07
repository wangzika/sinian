//
//  SinianIslandWidget.swift
//  SinianIslandWidget
//

import WidgetKit
import SwiftUI
import ActivityKit

struct SinianIslandLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissYouAttributes.self) { context in
            // 锁屏界面展示
            LockScreenActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // 展开态 Leading (发送方)
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.pink.opacity(0.6), Color.purple.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            Text(context.state.emoji)
                                .font(.system(size: 22))
                        }
                        Text(context.state.senderName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 6)
                }

                // 展开态 Trailing (接收方)
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 3) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 19))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.pulse, options: .repeating)
                        }
                        Text(context.state.partnerName)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 6)
                }

                // 展开态 Center
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                            .symbolEffect(.variableColor.iterative)
                        Text("心跳连线")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                            .symbolEffect(.variableColor.iterative)
                    }
                }

                // 展开态 Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.state.message)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                    .symbolEffect(.bounce, value: context.state.missCount)
                                Text("今日想念 \(context.state.missCount) 次")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Link(destination: URL(string: "sinian://dismiss")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 11))
                                        Text("我知道啦")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.18))
                                    )
                                }

                                Link(destination: URL(string: "sinian://reply")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 11))
                                        Text("我也想你")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.pink, .red],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                // 紧凑态左侧：未读思念时才显示跳动爱心与昵称，已读后完全隐藏不占岛
                if context.state.isUnread {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.pink)
                            .symbolEffect(.pulse, options: .repeating)
                        Text(context.state.senderName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
            } compactTrailing: {
                // 紧凑态右侧：未读思念时高亮显示表情与“想你啦”，已读后完全隐藏
                if context.state.isUnread {
                    HStack(spacing: 3) {
                        Text(context.state.emoji)
                            .font(.system(size: 12))
                        Text("想你啦")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.trailing, 4)
                }
            } minimal: {
                // 极小态：未读时显示跳动爱心与表情，已读后隐藏
                if context.state.isUnread {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.pink)
                            .symbolEffect(.pulse, options: .repeating)
                        Text(context.state.emoji)
                            .font(.system(size: 9))
                    }
                }
            }
            .keylineTint(context.state.isUnread ? .pink : .clear)
            .widgetURL(URL(string: "sinian://open_message")!)
        }
    }
}
