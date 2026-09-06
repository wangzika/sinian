//
//  HeartbeatButton.swift
//  Sinian
//

import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var opacity: Double
    var emoji: String
}

public struct HeartbeatButton: View {
    public var onShortTap: (String) -> Void
    public var onLongPressEnd: (String) -> Void

    @State private var isBreathing = false
    @State private var isPressed = false
    @State private var chargeProgress: CGFloat = 0.0
    @State private var chargeTimer: Timer?
    @State private var particles: [Particle] = []
    @State private var selectedEmoji: String = "❤️"

    private let emojis = ["❤️", "💖", "🥰", "💌", "✨", "🫂"]

    public init(
        onShortTap: @escaping (String) -> Void,
        onLongPressEnd: @escaping (String) -> Void
    ) {
        self.onShortTap = onShortTap
        self.onLongPressEnd = onLongPressEnd
    }

    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // 背景光晕层
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.pink.opacity(chargeProgress > 0 ? 0.45 : 0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 130
                        )
                    )
                    .frame(width: 260, height: 260)
                    .scaleEffect(isBreathing ? 1.08 : 0.95)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isBreathing)

                // 蓄力长按光环
                if chargeProgress > 0 {
                    Circle()
                        .trim(from: 0, to: chargeProgress)
                        .stroke(
                            AngularGradient(
                                colors: [.pink, .red, .orange, .pink],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 190, height: 190)
                        .rotationEffect(.degrees(-90))
                }

                // 心形主按钮
                Button(action: {}) {
                    ZStack {
                        // 磨砂玻璃圆底
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.red.opacity(0.85),
                                        Color.pink.opacity(0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 160)
                            .shadow(color: Color.pink.opacity(0.45), radius: 24, x: 0, y: 12)

                        VStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 54, weight: .bold))
                                .foregroundColor(.white)
                                .scaleEffect(isPressed ? 0.9 : 1.0)

                            Text(chargeProgress > 0 ? "蓄力中..." : "想你了")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.92 : (isBreathing ? 1.02 : 0.98))
                .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                                HapticManager.shared.playHeartbeat()
                                startCharging()
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            finishGesture()
                        }
                )

                // 浮空喷涌粒子层
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: 26))
                        .scaleEffect(particle.scale)
                        .opacity(particle.opacity)
                        .offset(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                isBreathing = true
            }

            // 情绪选择横滑栏
            HStack(spacing: 12) {
                ForEach(emojis, id: \.self) { emoji in
                    Button(action: {
                        selectedEmoji = emoji
                        HapticManager.shared.playTap()
                    }) {
                        Text(emoji)
                            .font(.system(size: 24))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(selectedEmoji == emoji ? Color.pink.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(selectedEmoji == emoji ? Color.pink : Color.clear, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
    }

    private func startCharging() {
        chargeProgress = 0.0
        chargeTimer?.invalidate()
        chargeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if chargeProgress < 1.0 {
                chargeProgress += 0.05
                if Int(chargeProgress * 20) % 4 == 0 {
                    HapticManager.shared.playTap()
                }
            } else {
                timer.invalidate()
                HapticManager.shared.playConfirmation()
            }
        }
    }

    private func finishGesture() {
        chargeTimer?.invalidate()
        chargeTimer = nil

        spawnParticles(count: chargeProgress >= 0.8 ? 14 : 7)

        if chargeProgress >= 0.8 {
            onLongPressEnd(selectedEmoji)
        } else {
            onShortTap(selectedEmoji)
        }
        chargeProgress = 0.0
    }

    private func spawnParticles(count: Int) {
        for _ in 0..<count {
            let p = Particle(
                x: CGFloat.random(in: -30...30),
                y: CGFloat.random(in: -20...20),
                scale: CGFloat.random(in: 0.6...1.2),
                opacity: 1.0,
                emoji: selectedEmoji
            )
            particles.append(p)

            let targetX = CGFloat.random(in: -100...100)
            let targetY = CGFloat.random(in: -180...(-80))

            withAnimation(.easeOut(duration: Double.random(in: 0.8...1.4))) {
                if let index = particles.firstIndex(where: { $0.id == p.id }) {
                    particles[index].x = targetX
                    particles[index].y = targetY
                    particles[index].opacity = 0
                    particles[index].scale = 1.6
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles.removeAll()
        }
    }
}
