import SwiftUI

/// Painel contextual para edição da nota musical de um obstáculo selecionado.
///
/// Exibe um controle do tipo `Slider` que permite ajuste rápido e intuitivo da altura (pitch) do som.
struct NoteEditorPanel: View {
    
    /// Binding para o índice da nota selecionada no ViewModel.
    @Binding var selectedNoteIndex: Int
    
    /// Callback para notificar interação (resetar timer de visibilidade).
    var onInteraction: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 12) {
            // Cabeçalho
            HStack {
                Text("AFINAÇÃO")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Valor atual
                Text("Tom \(selectedNoteIndex + 1)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.cyan.opacity(0.2), in: Capsule())
            }
            
            // Controle Deslizante (Slider)
            HStack(spacing: 12) {
                // Ícone Grave
                Image(systemName: "music.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Slider com feedback tátil
                Slider(
                    value: Binding(
                        get: { Double(selectedNoteIndex) },
                        set: { newValue in
                            let newIndex = Int(newValue)
                            if newIndex != selectedNoteIndex {
                                // Feedback tátil ao mudar de "degrau"
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedNoteIndex = newIndex
                                onInteraction()
                            }
                        }
                    ),
                    in: 0...13,
                    step: 1
                )
                .tint(.cyan)
                
                // Ícone Agudo
                Image(systemName: "music.quarternote.3")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        // Sombra suave para destacar do fundo
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24) // Margem lateral ajustada
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onTapGesture {
            onInteraction()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NoteEditorPanel(selectedNoteIndex: .constant(5))
    }
}