import SwiftUI

/// Painel contextual para edição da nota musical de um obstáculo selecionado.
///
/// Exibe um controle do tipo `Stepper` que permite ao usuário ciclar entre as notas disponíveis na escala harmônica do jogo.
/// Aparece apenas quando um objeto editável está selecionado na cena.
struct NoteEditorPanel: View {
    
    /// Binding para o índice da nota selecionada no ViewModel.
    @Binding var selectedNoteIndex: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Configurar Nota")
                .font(.caption2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.cyan)
                
                Stepper(value: $selectedNoteIndex, in: 0...13) {
                    Text("Tom \(selectedNoteIndex + 1)")
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
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        NoteEditorPanel(selectedNoteIndex: .constant(0))
    }
}
