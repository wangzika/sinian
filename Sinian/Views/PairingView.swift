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

                    HStack {
                        Spacer()
                        Button(action: {
                            inputServerURL = "ws://172.20.10.12:8080"
                            HapticManager.shared.playTap()
                        }) {
                            Text("填入 Mac 地址 (172.20.10.12)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.pink)
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

                Section(header: Text("联机指南"), footer: Text("📌 手机与电脑模拟器联机：\n1. 手机和 Mac 保持在同一 Wi-Fi 或手机热点下\n2. 信令服务填入：ws://172.20.10.12:8080\n3. 配对暗号必须完全一致（例如 LOVE-520）\n4. 点击『连接并配对』，状态变为『伴侣在线直连』即可互相触发灵动岛！")) {
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
                #if !targetEnvironment(simulator)
                if pairSession.serverURL.contains("localhost") || pairSession.serverURL.contains("127.0.0.1") {
                    inputServerURL = "ws://172.20.10.12:8080"
                } else {
                    inputServerURL = pairSession.serverURL
                }
                #else
                inputServerURL = pairSession.serverURL
                #endif
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
