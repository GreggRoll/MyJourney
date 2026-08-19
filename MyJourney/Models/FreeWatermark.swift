import SwiftUI

enum FreeWatermark {
    static let text = "Made with My Journey · FREE"
}

struct FreeWatermarkView: View {
    var body: some View {
        Text(FreeWatermark.text)
            .font(.title3.weight(.black))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.black.opacity(0.68), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.35), radius: 8, y: 3)
            .rotationEffect(.degrees(-7))
            .accessibilityIdentifier("freeWatermark")
            .accessibilityLabel("Made with My Journey Free watermark")
    }
}
