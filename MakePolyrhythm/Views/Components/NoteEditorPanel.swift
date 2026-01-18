import SwiftUI

struct NoteEditorPanel: View {
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
