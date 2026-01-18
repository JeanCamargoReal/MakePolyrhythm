import SwiftUI
import SpriteKit

/// Interface de usuário principal da aplicação MakePolyrhythm.
///
/// Esta View é responsável por integrar a cena do SpriteKit (`PolyrhythmScene`) com a interface nativa do SwiftUI.
/// Ela gerencia:
/// - A renderização da `SpriteView`.
/// - A camada de controles flutuantes (Dock) para adicionar elementos e controlar a simulação.
/// - A detecção de gestos de magnificação (pinça) e rotação para manipulação direta de objetos na cena.
struct ContentView: View {
    
    /// ViewModel que gerencia o estado da simulação e a comunicação com a cena SpriteKit.
    @State private var viewModel = SimulationViewModel()
    
    /// Controla a visibilidade dos controles de sobreposição (Dock).
    @State private var showControls = false
    
    /// Timer utilizado para ocultar automaticamente os controles após um período de inatividade.
    @State private var hideTimer: Timer?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Fundo / Cena
            SpriteView(scene: viewModel.scene)
                .ignoresSafeArea()
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                viewModel.handleScaleChange(scale: value)
                            }
                            .onEnded { _ in
                                viewModel.handleScaleEnd()
                            },
                        RotationGesture()
                            .onChanged { value in
                                viewModel.handleRotationChange(angle: value)
                            }
                            .onEnded { _ in
                                viewModel.handleRotationEnd()
                            }
                    )
                )
            
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
                VStack(spacing: 15) {
                    
                    // Editor de Nota (Aparece se objeto selecionado)
                    if viewModel.isObjectSelected {
                        VStack(spacing: 8) {
                            Text("Configurar Nota")
                                .font(.caption2)
                                .textCase(.uppercase)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                Image(systemName: "music.note")
                                    .foregroundStyle(.cyan)
                                
                                Stepper(value: $viewModel.selectedNoteIndex, in: 0...13) {
                                    Text("Tom \(viewModel.selectedNoteIndex + 1)")
                                        .font(.headline)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    HStack(spacing: 20) {
                        
                        HStack(spacing: 12) {
                            GlassyButton(icon: "circle.fill", label: "Add Bola") {
                                performWithTimer { viewModel.addBall() }
                            }
                            
                            Menu {
                                Button {
                                    performWithTimer { viewModel.addObstacle() }
                                } label: {
                                    Label("Retângulo", systemImage: "square.fill")
                                }
                                Button {
                                    performWithTimer { viewModel.addTriangle() }
                                } label: {
                                    Label("Triângulo", systemImage: "triangle.fill")
                                }
                                Button {
                                    performWithTimer { viewModel.addHexagon() }
                                } label: {
                                    Label("Hexágono", systemImage: "hexagon.fill")
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
                        
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(width: 1, height: 20)
                        
                        GlassyButton(
                            icon: viewModel.isPaused ? "play.fill" : "pause.fill",
                            label: viewModel.isPaused ? "Play" : "Pause"
                        ) {
                            performWithTimer { viewModel.togglePause() }
                        }
                        .contentTransition(.symbolEffect(.replace))
                        
                        Rectangle()
                            .fill(.secondary.opacity(0.3))
                            .frame(width: 1, height: 20)
                        
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
                }
                .padding(.bottom, 15)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
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