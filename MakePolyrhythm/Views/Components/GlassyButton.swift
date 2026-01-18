import SwiftUI

/// Um botão circular estilizado com efeito de vidro fosco e animação de toque elástica.
///
/// Utilizado para ações principais na interface do usuário, mantendo uma estética leve e moderna.
struct GlassyButton: View {
    
    /// Nome do ícone do sistema (SF Symbol) a ser exibido.
    let icon: String
    
    /// Texto descritivo para acessibilidade (VoiceOver).
    let label: String
    
    /// Cor de destaque do ícone. Padrão é `.primary`.
    var color: Color = .primary
    
    /// Ação a ser executada quando o botão é pressionado.
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2) // Aumentado para proporção
                .fontWeight(.medium)
                .foregroundStyle(color)
                .frame(width: 44, height: 44) // Aumentado para 44pt (Padrão Apple HIG)
                .contentShape(Circle())
        }
        .accessibilityLabel(label)
        .buttonStyle(BouncyButtonStyle())
    }
}

/// Estilo de botão personalizado que aplica uma animação de escala ("bounce") e opacidade ao ser pressionado.
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        GlassyButton(icon: "star.fill", label: "Example Button") {
            print("Button tapped")
        }
    }
}
