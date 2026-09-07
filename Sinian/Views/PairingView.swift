//
//  PairingView.swift
//  Sinian
//

import SwiftUI

public struct PairingView: View {
    @ObservedObject var pairSession = PairSession.shared
    @ObservedObject var syncService = SyncService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var inputPairCode: String = ""
    @State private var inputServerURL: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("情侣称呼")) {
                    HStack {
                        Text("我的昵称")
                            .frame(width: 80, alignment: .leading)
                        TextField("例如：宝贝", text: $pairSession.myNickname)
                    }
                    HStack {
                        Text("Ta 的昵称")
                            .frame(width: 80, alignment: .leading)
                        TextField("例如：猪猪", text: $pairSession.partnerNickname)
                    }
                }

                Section(header: Text("配对连接")) {
                    HStack {
                        Text("配对暗号")
                            .frame(width: 80, alignment: .leading)
                        TextField("例如：LOVE52", text: $inputPairCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        Button(action: generateRandomCode) {
                            Text("随机生成")
                                .font(.system(size: 13))
                        }
                    }

                    HStack {
                        Text("信令服务")
                            .frame(width: 80, alignment: .leading)
                        TextField("ws://...", text: $inputServerURL)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            inputServerURL = "wss://sinian-server.onrender.com"
                            HapticManager.shared.playTap()
                        }) {
                            HStack {
                                Image(systemName: "cloud.fill")
                                    .foregroundColor(.purple)
                                Text("填入免梯云端服务 (Render 推荐)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.purple)
                                Spacer()
                                Text("公网异地 7x24h")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }

                        HStack(spacing: 12) {
                            Spacer()
                            Button(action: {
                                inputServerURL = "ws://192.168.3.36:8080"
                                HapticManager.shared.playTap()
                            }) {
                                Text("局域网 (192.168.3.36)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                inputServerURL = "ws://172.20.10.12:8080"
                                HapticManager.shared.playTap()
                            }) {
                                Text("热点 (172.20.10.12)")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text("连接状态")
                        Spacer()
                        HStack(spacing: 6) {
                            if syncService.partnerOnline {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("伴侣在线直连 (已就绪)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            } else if syncService.isConnected {
                                Circle().fill(Color.orange).frame(width: 8, height: 8)
                                Text("已连接服务 (等待伴侣加入)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.orange)
                            } else {
                                Circle().fill(Color.gray).frame(width: 8, height: 8)
                                Text("离线 / 未连接")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(action: toggleConnection) {
                        HStack {
                            Spacer()
                            Text(syncService.isConnected ? "重新连接 / 刷新" : "连接并配对")
                                .fontWeight(.semibold)
                                .foregroundColor(syncService.isConnected ? .blue : .pink)
                            Spacer()
                        }
                    }
                }

                Section(header: Text("联机指南"), footer: Text("📌 随时随地异地/公网联机：\n1. 默认已配置云端免梯服务：wss://sinian-server.onrender.com\n2. 双方手机保持【配对暗号】完全一致（例如 LOVE-520）\n3. 无论身处何地、使用 4G/5G 移动流量还是 Wi-Fi，无需电脑开机，灵动岛与锁屏通知即时送达！")) {
                    EmptyView()
                }
            }
            .navigationTitle("甜蜜配对")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                inputPairCode = pairSession.pairCode.isEmpty ? "LOVE-520" : pairSession.pairCode
                if pairSession.serverURL.contains("192.168.") || pairSession.serverURL.contains("172.20.") || pairSession.serverURL.contains("localhost") || pairSession.serverURL.contains("127.0.0.1") {
                    inputServerURL = "wss://sinian-server.onrender.com"
                } else {
                    inputServerURL = pairSession.serverURL
                }
            }
        }
    }

    private func generateRandomCode() {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let randomStr = String((0..<4).map { _ in letters.randomElement()! })
        inputPairCode = "LOVE-\(randomStr)"
        HapticManager.shared.playTap()
    }

    private func toggleConnection() {
        pairSession.pairCode = inputPairCode
        pairSession.serverURL = inputServerURL

        if syncService.isConnected {
            syncService.disconnect()
        } else {
            syncService.connect(url: inputServerURL, pairCode: inputPairCode)
        }
    }
}
