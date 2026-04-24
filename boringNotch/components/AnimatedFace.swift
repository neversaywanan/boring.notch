//
//  AnimatedFace.swift
//
// Created by Harsh Vardhan  Goswami  on  04/08/24.
//

import AppKit
import SwiftUI

enum CatExpression: Equatable {
    case neutral
    case happy
    case winking
    case sleeping
    case angry
}

enum CatEmotion: Equatable, CaseIterable {
    case zzz, happy, angry
}

@MainActor
final class FaceAnimationController: ObservableObject {
    @Published var isBlinking = false
    @Published var lookOffset: CGSize = .zero
    @Published var alertness: CGFloat = 0
    @Published var expression: CatExpression = .neutral
    @Published var winkSide: CatSide = .left
    @Published var activeEmotion: CatEmotion? = nil

    private var mouseTrackingTimer: Timer?
    private var blinkTimer: Timer?
    private var winkTimer: Timer?
    private var emotionTimer: Timer?

    private var isInteractive = false
    private var screenUUID: String?
    private var faceAnchorOffset: CGSize = .zero
    private var previousMouseLocation: CGPoint?
    private var previousSampleTime: TimeInterval?
    private var lastInteractionTime: TimeInterval = 0
    private var pettingCount: Int = 0
    private var interactionResetTask: Task<Void, Never>?
    private var sleepTask: Timer?

    func configure(interactive: Bool, screenUUID: String?, faceAnchorOffset: CGSize) {
        self.isInteractive = interactive
        self.screenUUID = screenUUID
        self.faceAnchorOffset = faceAnchorOffset

        if interactive {
            startMouseTrackingIfNeeded()
            startRandomEmotionCycle()
            startBlinkLoopIfNeeded()
            resetSleepTimer()
            // Show a heart on start
            triggerEmotion(.happy)
        } else {
            stopMouseTracking()
            settleFace()
        }
    }

    func stop() {
        stopMouseTracking()
        winkTimer?.invalidate()
        emotionTimer?.invalidate()
        blinkTimer?.invalidate()
        sleepTask?.invalidate()
        interactionResetTask?.cancel()
    }

    private func startMouseTrackingIfNeeded() {
        guard mouseTrackingTimer == nil else { return }

        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) {
            [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleInteraction()
            }
        }
        RunLoop.main.add(mouseTrackingTimer!, forMode: .common)
    }

    private func stopMouseTracking() {
        mouseTrackingTimer?.invalidate()
        mouseTrackingTimer = nil
    }

    private func startBlinkLoopIfNeeded() {
        guard blinkTimer == nil else { return }
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.blink()
            }
        }
    }

    private func blink() async {
        guard !isBlinking else { return }
        withAnimation(.easeInOut(duration: 0.1)) { isBlinking = true }
        try? await Task.sleep(nanoseconds: 120_000_000)
        withAnimation(.easeInOut(duration: 0.15)) { isBlinking = false }
    }

    private func settleFace() {
        withAnimation(.easeOut(duration: 0.25)) {
            lookOffset = .zero
            alertness = 0
            expression = .neutral
            activeEmotion = nil
        }
        previousMouseLocation = nil
        previousSampleTime = nil
        interactionResetTask?.cancel()
    }

    private func handleInteraction() {
        guard isInteractive else { return }
        guard let screenFrame = getScreenFrame(screenUUID) else { return }

        let now = Date().timeIntervalSinceReferenceDate
        let mouseLocation = NSEvent.mouseLocation
        let faceAnchor = CGPoint(
            x: screenFrame.midX + faceAnchorOffset.width,
            y: screenFrame.maxY - faceAnchorOffset.height
        )

        let dx = mouseLocation.x - faceAnchor.x
        let dy = mouseLocation.y - faceAnchor.y 
        
        let vx = (previousMouseLocation != nil && previousSampleTime != nil) ? 
            (mouseLocation.x - previousMouseLocation!.x) / max(0.001, now - previousSampleTime!) : 0
        
        previousMouseLocation = mouseLocation
        previousSampleTime = now

        let isSwiping = abs(vx) > 350 && abs(dx) < 60
        let isFastSwiping = abs(vx) > 850 && abs(dx) < 60

        if (dy > 5 && dy < 60 && isSwiping) || (dy < -5 && dy > -60 && isFastSwiping) {
            resetSleepTimer()
            
            if expression == .sleeping {
                // Wake up angry!
                triggerExpression(.angry)
                triggerEmotion(.angry)
                pettingCount = 0
                return
            }
            
            if dy > 5 && dy < 60 && isSwiping {
                // Petting on top
                if expression == .angry {
                    pettingCount += 1
                    if pettingCount >= 5 {
                        triggerExpression(.happy)
                        triggerEmotion(.happy)
                        pettingCount = 0
                    } else {
                        // Still angry, but receiving pets
                        triggerEmotion(.angry) 
                    }
                } else {
                    triggerExpression(.happy)
                    triggerEmotion(.happy)
                }
            } else if dy < -5 && dy > -60 && isFastSwiping {
                // Tickling below
                if expression != .angry {
                    triggerExpression(.winking)
                }
            }
        }
    }

    private func resetSleepTimer() {
        sleepTask?.invalidate()
        sleepTask = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.goToSleep()
            }
        }
    }

    private func goToSleep() {
        guard expression == .neutral else { return }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            expression = .sleeping
        }
        triggerEmotion(.zzz)
    }

    private func triggerExpression(_ newExpr: CatExpression) {
        lastInteractionTime = Date().timeIntervalSinceReferenceDate
        
        if expression != newExpr {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                expression = newExpr
                lookOffset = .zero // Head tilt removed
            }
            
            if newExpr == .winking {
                startWinkCycle()
            } else {
                stopWinkCycle()
            }
        }
        
        // Reset to neutral after 2.5 seconds of no activity (longer to allow multiple pets)
        interactionResetTask?.cancel()
        interactionResetTask = Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            
            // If we are angry, we stay angry longer? No, let's just go back to neutral
            withAnimation(.easeOut(duration: 0.3)) {
                if self.expression != .sleeping {
                    self.expression = .neutral
                    self.activeEmotion = nil // Ensure emotion icon is cleared
                }
            }
            self.stopWinkCycle()
            self.pettingCount = 0
        }
    }

    private func startWinkCycle() {
        guard winkTimer == nil else { return }
        winkTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.winkSide = (self?.winkSide == .left) ? .right : .left
            }
        }
    }

    private func stopWinkCycle() {
        winkTimer?.invalidate()
        winkTimer = nil
    }

    private func triggerEmotion(_ emotion: CatEmotion) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            activeEmotion = emotion
        }
        
        emotionTimer?.invalidate()
        
        // ZZZ and Angry persist as long as the state is active
        // Others fade out after 3.5 seconds
        if emotion != .zzz && emotion != .angry {
            emotionTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    // Only clear if we haven't switched to a persistent emotion
                    if self?.activeEmotion != .zzz && self?.activeEmotion != .angry {
                        withAnimation(.easeOut(duration: 0.5)) {
                            self?.activeEmotion = nil
                        }
                    }
                }
            }
        }
    }

    private func startRandomEmotionCycle() {
        emotionTimer?.invalidate()
        let interval = Double.random(in: 15...45)
        emotionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                if self?.expression == .neutral {
                    let randomEmotion = CatEmotion.allCases.randomElement()!
                    self?.triggerEmotion(randomEmotion)
                }
                self?.startRandomEmotionCycle()
            }
        }
    }

    private func clampedOffset(_ offset: CGSize) -> CGSize {
        CGSize(
            width: max(-5.0, min(offset.width, 5.0)),
            height: max(-3.5, min(offset.height, 3.5))
        )
    }
}

struct MinimalFaceFeatures: View {
    @StateObject private var animationController = FaceAnimationController()

    var screenUUID: String? = nil
    var faceAnchorOffset: CGSize = .zero
    var interactive: Bool = false
    var height: CGFloat = 20
    var width: CGFloat = 32

    var body: some View {
        GeometryReader { geometry in
            CuriousCatFace(
                isBlinking: animationController.isBlinking,
                lookOffset: animationController.lookOffset,
                alertness: animationController.alertness,
                expression: animationController.expression,
                winkSide: animationController.winkSide,
                activeEmotion: animationController.activeEmotion,
                canvasSize: geometry.size
            )
        }
        .frame(width: width, height: height)
        .onAppear {
            animationController.configure(
                interactive: interactive,
                screenUUID: screenUUID,
                faceAnchorOffset: faceAnchorOffset
            )
        }
        .onChange(of: interactive) { _, newValue in
            animationController.configure(
                interactive: newValue,
                screenUUID: screenUUID,
                faceAnchorOffset: faceAnchorOffset
            )
        }
        .onChange(of: screenUUID) { _, newValue in
            animationController.configure(
                interactive: interactive,
                screenUUID: newValue,
                faceAnchorOffset: faceAnchorOffset
            )
        }
        .onChange(of: faceAnchorOffset) { _, newValue in
            animationController.configure(
                interactive: interactive,
                screenUUID: screenUUID,
                faceAnchorOffset: newValue
            )
        }
        .onDisappear {
            animationController.stop()
        }
    }
}

struct CuriousCatFace: View {
    let isBlinking: Bool
    let lookOffset: CGSize
    let alertness: CGFloat
    let expression: CatExpression
    let winkSide: CatSide
    let activeEmotion: CatEmotion?
    let canvasSize: CGSize

    private var headTilt: Double {
        if expression == .sleeping { return 10.0 }
        return 0
    }

    private var faceOffset: CGSize {
        lookOffset
    }

    var body: some View {
        let strokeWidth = max(1.5, min(canvasSize.width, canvasSize.height) * 0.08)

        ZStack {
            // Emotion Icon at top-left
            if let emotion = activeEmotion {
                EmotionIconView(emotion: emotion, canvasSize: canvasSize)
                    .offset(x: -canvasSize.width * 0.35, y: -canvasSize.height * 0.45)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                        removal: .opacity.combined(with: .scale(scale: 0.5))
                    ))
            }

            CatHeadOutline(
                canvasSize: canvasSize,
                alertness: alertness,
                expression: expression,
                strokeWidth: strokeWidth
            )

            CatEye(
                side: .left,
                canvasSize: canvasSize,
                isBlinking: isBlinking || expression == .happy,
                alertness: alertness,
                expression: expression,
                winkSide: winkSide
            )
            .offset(
                x: canvasSize.width * -0.20 + faceOffset.width,
                y: canvasSize.height * -0.02 + faceOffset.height
            )

            CatEye(
                side: .right,
                canvasSize: canvasSize,
                isBlinking: isBlinking || expression == .happy,
                alertness: alertness,
                expression: expression,
                winkSide: winkSide
            )
            .offset(
                x: canvasSize.width * 0.20 + faceOffset.width,
                y: canvasSize.height * -0.02 + faceOffset.height
            )

            CatNoseAndMouth(
                canvasSize: canvasSize,
                alertness: alertness,
                expression: expression
            )
            .offset(x: faceOffset.width * 0.6, y: canvasSize.height * 0.18 + faceOffset.height)

//            CatWhiskers(
//                side: .left,
//                canvasSize: canvasSize,
//                alertness: alertness,
//                expression: expression,
//                strokeWidth: strokeWidth
//            )
//            .offset(x: -canvasSize.width * 0.12, y: canvasSize.height * 0.18)

//            CatWhiskers(
//                side: .right,
//                canvasSize: canvasSize,
//                alertness: alertness,
//                expression: expression,
//                strokeWidth: strokeWidth
//            )
//            .offset(x: canvasSize.width * 0.12, y: canvasSize.height * 0.18)
        }
        .rotationEffect(.degrees(headTilt))
        .offset(faceOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: lookOffset)
        .animation(.easeOut(duration: 0.2), value: alertness)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: expression)
    }
}

struct EmotionIconView: View {
    let emotion: CatEmotion
    let canvasSize: CGSize
    
    var body: some View {
        let size = canvasSize.width * 0.32
        Group {
            switch emotion {
            case .zzz: zzzIcon
            case .happy: happyIcon
            case .angry: angryIcon
            }
        }
        .frame(width: size, height: size)
        .foregroundColor(.white.opacity(0.9))
    }
    
    private var zzzIcon: some View {
        ZZZAnimationView()
    }
    
    private var happyIcon: some View {
        Image(systemName: "heart.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.red.opacity(0.9))
    }
    
    private var angryIcon: some View {
        Path { path in
            let s = canvasSize.width * 0.32
            // Two vertical-ish bulging curves
            path.move(to: CGPoint(x: s * 0.25, y: s * 0.1))
            path.addQuadCurve(to: CGPoint(x: s * 0.25, y: s * 0.9), control: CGPoint(x: s * 0.05, y: s * 0.5))
            
            path.move(to: CGPoint(x: s * 0.75, y: s * 0.1))
            path.addQuadCurve(to: CGPoint(x: s * 0.75, y: s * 0.9), control: CGPoint(x: s * 0.95, y: s * 0.5))
            
            // Two horizontal-ish bulging curves
            path.move(to: CGPoint(x: s * 0.1, y: s * 0.25))
            path.addQuadCurve(to: CGPoint(x: s * 0.9, y: s * 0.25), control: CGPoint(x: s * 0.5, y: s * 0.05))
            
            path.move(to: CGPoint(x: s * 0.1, y: s * 0.75))
            path.addQuadCurve(to: CGPoint(x: s * 0.9, y: s * 0.75), control: CGPoint(x: s * 0.5, y: s * 0.95))
        }
        .stroke(Color.red.opacity(0.95), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }
}

struct CatHeadOutline: View {
    let canvasSize: CGSize
    let alertness: CGFloat
    let expression: CatExpression
    let strokeWidth: CGFloat

    var body: some View {
        let isHappy = expression == .happy
        let earLift = canvasSize.height * 0.08 * alertness + (isHappy ? 2.5 : 0)

        Path { path in
            let w = canvasSize.width
            let h = canvasSize.height
            
            // Start top left base of ear
            path.move(to: CGPoint(x: w * 0.32, y: h * 0.35))
            
            // Left ear
            path.addLine(to: CGPoint(x: w * 0.20, y: h * 0.12 - earLift)) // ear tip
            path.addQuadCurve(
                to: CGPoint(x: w * 0.15, y: h * 0.45),
                control: CGPoint(x: w * 0.12, y: h * 0.25)
            )
            
            // Cheeks and chin
            path.addCurve(
                to: CGPoint(x: w * 0.85, y: h * 0.45),
                control1: CGPoint(x: w * -0.05, y: h * 0.95),
                control2: CGPoint(x: w * 1.05, y: h * 0.95)
            )
            
            // Right ear
            path.addQuadCurve(
                to: CGPoint(x: w * 0.80, y: h * 0.12 - earLift),
                control: CGPoint(x: w * 0.88, y: h * 0.25)
            )
            path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.35))
            
            // Top of head
            path.addQuadCurve(
                to: CGPoint(x: w * 0.32, y: h * 0.35),
                control: CGPoint(x: w * 0.5, y: h * 0.30)
            )
        }
        .stroke(
            Color.white,
            style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
        )
    }
}

enum CatSide {
    case left
    case right
}

struct CatEye: View {
    let side: CatSide
    let canvasSize: CGSize
    let isBlinking: Bool
    let alertness: CGFloat
    let expression: CatExpression
    let winkSide: CatSide

    private var eyeWidth: CGFloat {
        canvasSize.width * 0.22
    }

    private var eyeHeight: CGFloat {
        if expression == .winking && side == winkSide {
            return max(2.5, canvasSize.height * 0.04)
        }

        if expression == .sleeping || expression == .happy {
            return max(2.5, canvasSize.height * 0.04)
        }

        if expression == .angry {
            // Angry narrowed eyes
            return canvasSize.height * 0.15
        }

        guard !isBlinking else {
            return max(2.5, canvasSize.height * 0.04)
        }

        return canvasSize.height * (0.28 + alertness * 0.08)
    }

    private var rotation: Double {
        if expression == .angry {
            return side == .left ? 15.0 : -15.0 // Angled eyes
        }
        return side == .left ? -5.0 : 5.0
    }

    var body: some View {
        Group {
            if (expression == .winking && side == winkSide) || isBlinking || expression == .sleeping || expression == .happy {
                Capsule()
                    .fill(Color.white)
                    .frame(width: eyeWidth * 1.2, height: eyeHeight)
            } else if expression == .angry {
                // Angry sharp triangular-ish eyes
                Capsule()
                    .fill(Color.white)
                    .frame(width: eyeWidth * 1.1, height: eyeHeight)
            } else {
                Ellipse()
                    .fill(Color.white)
                    .frame(width: eyeWidth, height: eyeHeight)
            }
        }
        .rotationEffect(.degrees(rotation))
        .animation(.easeInOut(duration: 0.12), value: isBlinking)
        .animation(.easeOut(duration: 0.18), value: alertness)
    }
}

struct CatNoseAndMouth: View {
    let canvasSize: CGSize
    let alertness: CGFloat
    let expression: CatExpression

    var body: some View {
        let noseWidth = max(2.0, canvasSize.width * 0.06)
        let noseHeight = max(1.2, canvasSize.height * 0.04)

        ZStack {
            // Cute small oval nose
            Ellipse()
                .fill(Color.white)
                .frame(width: noseWidth, height: noseHeight)
                .offset(y: -noseHeight * 0.6)

            // "ω" mouth
//            Path { path in
//                let w = noseWidth * 1.5
//                let h = noseHeight * 1.2 + alertness * noseHeight * 0.6
//                
//                path.move(to: CGPoint(x: -w, y: h * 0.2))
//                path.addCurve(
//                    to: CGPoint(x: 0, y: h * 0.2),
//                    control1: CGPoint(x: -w, y: h),
//                    control2: CGPoint(x: 0, y: h)
//                )
//                path.addCurve(
//                    to: CGPoint(x: w, y: h * 0.2),
//                    control1: CGPoint(x: 0, y: h),
//                    control2: CGPoint(x: w, y: h)
//                )
//            }
//            .stroke(
//                Color.green,
//                style: StrokeStyle(lineWidth: max(1.0, canvasSize.height * 0.035), lineCap: .round)
//            )
        }
    }
}

struct CatWhiskers: View {
    let side: CatSide
    let canvasSize: CGSize
    let alertness: CGFloat
    let expression: CatExpression
    let strokeWidth: CGFloat

    private var direction: CGFloat {
        side == .left ? -1 : 1
    }

    var body: some View {
        Path { path in
            let width = canvasSize.width
            let height = canvasSize.height
            
            // Separation: start whiskers away from the center
            let startX: CGFloat = width * 0.10 * direction
            let endX = width * 0.32 * direction
            let alertLift = alertness * height * 0.02

            for index in 0..<3 {
                let angle = (CGFloat(index) - 1.0) * 0.25
                let y = (CGFloat(index) - 1.0) * height * 0.06
                let endY = y + angle * height * 0.12 + (direction * alertLift * 0.5)

                path.move(to: CGPoint(x: startX, y: y))
                path.addQuadCurve(
                    to: CGPoint(x: endX, y: endY),
                    control: CGPoint(
                        x: (startX + endX) / 2,
                        y: y + (CGFloat(index) - 1.0) * height * 0.01
                    )
                )
            }
        }
        .stroke(
            Color.white.opacity(0.65),
            style: StrokeStyle(lineWidth: strokeWidth * 0.28, lineCap: .round)
        )
    }
}

struct ZZZAnimationView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            zLetter(text: "Z", size: 8, offset: 0, delay: 0)
            zLetter(text: "z", size: 6, offset: 3, delay: 0.6)
            zLetter(text: "z", size: 4, offset: 6, delay: 1.2)
        }
        .onAppear {
            // Trigger animation with a slight delay to ensure onAppear is fully settled
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animate = true
            }
        }
    }

    @ViewBuilder
    private func zLetter(text: String, size: CGFloat, offset: CGFloat, delay: Double) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black))
            .offset(x: offset + (animate ? 4 : 0), y: animate ? -12 : 0)
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 1.2 : 0.6)
            .animation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: false)
                .delay(delay),
                value: animate
            )
    }
}

struct MinimalFaceFeatures_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            MinimalFaceFeatures()
        }
        .previewLayout(.fixed(width: 60, height: 60))
    }
}
