import SwiftUI

struct GlassyButton: View {
    let icon: String
    let label: String
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .contentShape(Circle())
        }
        .accessibilityLabel(label)
        .buttonStyle(BouncyButtonStyle())
    }
}

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .background(
                Circle()
                    .fill(.white.opacity(configuration.isPressed ? 0.2 : 0.0))
            )
    }
}
