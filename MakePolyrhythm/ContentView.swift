import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var viewModel = SimulationViewModel()
    
    var body: some View {
        ZStack {
            // Fundo / Cena
            SpriteView(scene: viewModel.scene)
                .ignoresSafeArea()
            
            // Overlay de Controles
            VStack {
                Spacer()
                
                // Floating Glass Dock
                HStack(spacing: 24) {
                    
                    // Grupo: Criação
                    HStack(spacing: 16) {
                        GlassyButton(icon: "circle.fill", label: "Add Bola") {
                            viewModel.addBall()
                        }
                        
                        GlassyButton(icon: "square.fill", label: "Add Objeto") {
                            viewModel.addObstacle()
                        }
                    }
                    
                    // Divisor Visual
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1, height: 24)
                    
                    // Grupo: Controle
                    GlassyButton(
                        icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                        label: viewModel.isPaused ? "Play" : "Pause"
                    ) {
                        viewModel.togglePause()
                    }
                    .contentTransition(.symbolEffect(.replace)) // Animação suave na troca de ícone
                    
                    // Divisor Visual
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1, height: 24)
                    
                    // Grupo: Destrutivo
                    GlassyButton(icon: "trash.fill", label: "Limpar", color: .red) {
                        viewModel.clearBalls()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Componentes de UI

struct GlassyButton: View {
    let icon: String
    let label: String // Para acessibilidade
    var color: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Circle()) // Aumenta a área de toque
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

#Preview {
    ContentView()
}