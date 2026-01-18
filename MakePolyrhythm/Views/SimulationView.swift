import SwiftUI
import SpriteKit

/// View principal da aplicação MakePolyrhythm.
///
/// Responsável por orquestrar a interface do usuário, integrando a cena de simulação (`SpriteView`)
/// com os controles flutuantes de sobreposição (UI).
///
/// Gerencia:
/// - A exibição da cena SpriteKit.
/// - A visibilidade e interação dos controles (Dock e Painéis).
/// - A captura de gestos globais (Pinça e Rotação) para manipulação de objetos na cena.
struct SimulationView: View {
    
    /// ViewModel que detém a lógica de negócio e o estado da simulação.
    @State private var viewModel = SimulationViewModel()
    
    /// Controla a visibilidade dos controles flutuantes (Dock e Painéis).
    @State private var showControls = false
    
    /// Timer para ocultar automaticamente os controles após inatividade.
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
                        NoteEditorPanel(selectedNoteIndex: $viewModel.selectedNoteIndex)
                    }
                    
                    // Floating Glass Dock (Controles Principais)
                    FloatingControlsDock(viewModel: viewModel) {
                        showControlsWithTimer()
                    }
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

#Preview {
    SimulationView()
}