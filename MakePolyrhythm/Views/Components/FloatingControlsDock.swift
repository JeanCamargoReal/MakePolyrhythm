import SwiftUI

/// Painel flutuante inferior contendo os controles principais da simulação.
///
/// Agrupa botões para:
/// - Criação de entidades (Bolas, Obstáculos).
/// - Controle de fluxo (Play/Pause).
/// - Ações destrutivas (Limpar).
///
/// O painel utiliza um estilo visual translúcido ("Glassy") para se integrar à cena sem obstruir a visão.
struct FloatingControlsDock: View {
    
    /// ViewModel para executar as ações de lógica de negócio.
    var viewModel: SimulationViewModel
    
    /// Callback acionado em qualquer interação, utilizado para resetar timers de inatividade na View pai.
    var onInteraction: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            
            // Grupo: Criação
            HStack(spacing: 12) {
                GlassyButton(icon: "circle.fill", label: "Add Bola") {
                    performAction { viewModel.addBall() }
                }
                
                // Menu de Formas
                Menu {
                    Button {
                        performAction { viewModel.addObstacle() }
                    } label: {
                        Label("Retângulo", systemImage: "square.fill")
                    }
                    
                    Button {
                        performAction { viewModel.addTriangle() }
                    } label: {
                        Label("Triângulo", systemImage: "triangle.fill")
                    }
                    
                    Button {
                        performAction { viewModel.addHexagon() }
                    } label: {
                        Label("Hexágono", systemImage: "hexagon.fill")
                    }
                    
                    Button {
                        performAction { viewModel.addDiamond() }
                    } label: {
                        Label("Losango", systemImage: "diamond.fill")
                    }
                } label: {
                    Image(systemName: "plus.square.fill.on.square.fill")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .frame(width: 38, height: 38)
                        .contentShape(Circle())
                }
            }
            
            // Divisor
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1, height: 20)
            
            // Grupo: Controle
            GlassyButton(
                icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                label: viewModel.isPaused ? "Play" : "Pause"
            ) {
                performAction { viewModel.togglePause() }
            }
            .contentTransition(.symbolEffect(.replace))
            
            // Divisor
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(width: 1, height: 20)
            
            // Grupo: Destrutivo
            GlassyButton(icon: "trash.fill", label: "Limpar", color: .red) {
                performAction { viewModel.clearBalls() }
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
    }
    
    private func performAction(_ action: () -> Void) {
        action()
        onInteraction()
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FloatingControlsDock(viewModel: SimulationViewModel()) {
            print("Interaction detected")
        }
    }
}
