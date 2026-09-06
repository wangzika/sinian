//
//  HapticManager.swift
//  Sinian
//

import UIKit
import CoreHaptics

public final class HapticManager {
    public static let shared = HapticManager()

    private var hapticEngine: CHHapticEngine?
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("[HapticManager] 无法启动 Haptic 引擎: \(error.localizedDescription)")
        }
    }

    /// 播放轻触反馈
    public func playTap() {
        lightImpact.impactOccurred()
    }

    /// 播放强烈确认反馈
    public func playConfirmation() {
        mediumImpact.impactOccurred()
    }

    /// 播放浪漫心跳触觉节律 ("咚-咚...咚-咚...")
    public func playHeartbeat() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine = hapticEngine else {
            // 回退到 UIImpactFeedbackGenerator
            playFallbackHeartbeat()
            return
        }

        do {
            let firstBeat = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0
            )

            let secondBeat = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.18
            )

            let pattern = try CHHapticPattern(events: [firstBeat, secondBeat], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            playFallbackHeartbeat()
        }
    }

    private func playFallbackHeartbeat() {
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.heavyImpact.impactOccurred()
        }
    }

    /// 播放收到对方想念时的欣喜震动
    public func playPartnerMissNotification() {
        notificationFeedback.notificationOccurred(.success)
    }
}
