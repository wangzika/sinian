//
//  LockScreenActivityView.swift
//  SinianIslandWidget
//

import SwiftUI
import WidgetKit
import ActivityKit

public struct LockScreenActivityView: View {
    public let context: ActivityViewContext<MissYouAttributes>

    public init(context: ActivityViewContext<MissYouAttributes>) {
        self.context = context
    }

    public var body: some View {
        VStack(spacing: 12) {
            // 顶栏：发送者与时间
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.2))
                        .frame(width: 32, height: 32)
                    Text(context.state.emoji)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(context.state.senderName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)

                        Text("正在想你")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pink)
                    }

                    Text(context.state.lastSentAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // 想念计数气泡
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.pink)
                    Text("第 \(context.state.missCount) 次")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.pink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.pink.opacity(0.12))
                )
            }

            // 中间：想念留言气泡
            HStack {
                Text(context.state.message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground).opacity(0.8))
            )

            // 底部：互动引导与浪漫回音
            HStack {
                Text("“所爱隔山海，山海皆可平”")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.secondary.opacity(0.8))

                Spacer()

                Link(destination: URL(string: "sinian://reply")!) {
                    HStack(spacing: 4) {
                        Text("回赠心跳")
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.pink)
                }
            }
        }
        .padding(16)
        .background(
            Color(UIColor.systemBackground).opacity(0.95)
        )
        .widgetURL(URL(string: "sinian://open_message")!)
    }
}
