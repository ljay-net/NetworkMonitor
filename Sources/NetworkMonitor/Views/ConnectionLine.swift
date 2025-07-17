import SwiftUI

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            Color.gray.opacity(0.5),
            style: StrokeStyle(
                lineWidth: 1,
                dash: [5, 5],
                dashPhase: animationPhase
            )
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                animationPhase = 10
            }
        }
    }
}