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
                                .fill(Color.pink.opacity(0.3))
                                .frame(width: 38, height: 38)
                            Text(context.state.emoji)
                                .font(.system(size: 20))
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
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 38, height: 38)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.pink)
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
                        Text("心跳连线")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.pink)
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }

                // 展开态 Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.state.message)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 8)

                        HStack {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                Text("今日想念 \(context.state.missCount) 次")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Link(destination: URL(string: "sinian://dismiss")!) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle")
                                            .font(.system(size: 11))
                                        Text("收起")
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
                                            .fill(Color.pink)
                                    )
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 6)
                }
            } compactLeading: {
                // 紧凑态左侧：爱心 + 对方昵称（即使用户开热点导致右侧被分割，左侧文字依然一目了然！）
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.pink)
                    Text(context.state.senderName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(.leading, 4)
            } compactTrailing: {
                // 紧凑态右侧：表情与想念提示
                HStack(spacing: 2) {
                    Text(context.state.emoji)
                        .font(.system(size: 11))
                    Text("想你啦")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.pink)
                }
                .padding(.trailing, 4)
            } minimal: {
                // 极小态（双岛分割模式）：爱心 + 对方昵称首字
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                    Text(String(context.state.senderName.prefix(1)))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .keylineTint(.pink)
        }
    }
}
