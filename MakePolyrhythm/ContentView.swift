import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var viewModel = SimulationViewModel()
    @State private var showControls = false
    @State private var hideTimer: Timer?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Fundo / Cena
            SpriteView(scene: viewModel.scene)
                .ignoresSafeArea()
            
            // Área Sensível (Sensor de Proximidade/Toque)
            // Fica sempre ativa na parte inferior para "chamar" os controles
            Color.black.opacity(0.001) // Invisível mas interativo
                .frame(height: 120)
                .contentShape(Rectangle())
                .onTapGesture {
                    showControlsWithTimer()
                }
                // Permite hit testing apenas quando controles estão ocultos, 
                // para não bloquear a cena se o usuário quiser arrastar algo ali (embora o tap gesture possa conflitar levemente, é o compromisso da feature)
                // Na verdade, deixaremos sempre ativo para funcionar como "chamar menu", 
                // mas a ZStack coloca os controles POR CIMA disso quando visíveis.
            
            // Overlay de Controles
            if showControls {
                // Floating Glass Dock
                HStack(spacing: 20) {
                    
                    // Grupo: Criação
                    HStack(spacing: 12) {
                        GlassyButton(icon: "circle.fill", label: "Add Bola") {
                            performWithTimer { viewModel.addBall() }
                        }
                        
                        GlassyButton(icon: "cube.fill", label: "Add Objeto") {
                            performWithTimer { viewModel.addObstacle() }
                        }
                    }
                    
                    // Divisor Visual
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1, height: 20)
                    
                    // Grupo: Controle
                    GlassyButton(
                        icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                        label: viewModel.isPaused ? "Play" : "Pause"
                    ) {
                        performWithTimer { viewModel.togglePause() }
                    }
                    .contentTransition(.symbolEffect(.replace))
                    
                    // Divisor Visual
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(width: 1, height: 20)
                    
                    // Grupo: Destrutivo
                    GlassyButton(icon: "trash.fill", label: "Limpar", color: .red) {
                        performWithTimer { viewModel.clearBalls() }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
                .padding(.bottom, 15)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1) // Garante que fique acima do sensor
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showControls)
    }
    
    // MARK: - Lógica de Controle
    
    private func showControlsWithTimer() {
        // Mostra controles
        showControls = true
        
        // Reseta timer anterior
        hideTimer?.invalidate()
        
        // Configura novo timer para ocultar
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            showControls = false
        }
    }
    
    private func performWithTimer(action: @escaping () -> Void) {
        action()
        showControlsWithTimer() // Renova o timer ao interagir
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

#Preview {
    ContentView()
}