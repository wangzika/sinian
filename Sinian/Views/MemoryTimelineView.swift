//
//  MemoryTimelineView.swift
//  Sinian
//

import SwiftUI

public struct MemoryTimelineView: View {
    @ObservedObject var pairSession = PairSession.shared
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    public init() {}

    public var body: some View {
        CompatNavigationStack {
            List {
                // 顶部统计
                Section {
                    VStack(spacing: 8) {
                        Text("\(pairSession.todayMissCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.pink)
                        Text("今日想念总次数")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }

                // 历史流水
                Section(header: Text("甜蜜足迹")) {
                    if pairSession.historyEvents.isEmpty {
                        Text("今天还没有想念记录，快去点击心跳发送吧～")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(.vertical, 16)
                    } else {
                        ForEach(pairSession.historyEvents) { event in
                            HStack(spacing: 12) {
                                Text(event.emoji)
                                    .font(.system(size: 28))
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(event.isFromMe ? Color.pink.opacity(0.12) : Color.purple.opacity(0.12))
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(event.isFromMe ? "我" : event.senderName)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(event.isFromMe ? .pink : .purple)

                                        Text(event.actionType == "super_miss" ? "超级想念 🌟" : "轻拍了心跳")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.secondary)

                                        Spacer()

                                        Text(dateFormatter.string(from: event.timestamp))
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Text(event.message)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("想念足迹")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}
