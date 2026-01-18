import SwiftUI
import SpriteKit
import Observation

/// ViewModel responsável pela lógica de apresentação e controle da simulação física.
///
/// Atua como uma ponte entre a interface do usuário (SwiftUI) e a cena do SpriteKit (`PolyrhythmScene`).
/// Suas principais responsabilidades incluem:
/// - Gerenciar a instância da cena.
/// - Controlar o estado global da simulação (pausa/play).
/// - Receber e processar gestos da UI (escala e rotação) e aplicá-los aos objetos selecionados na cena.
/// - Expor comandos de ação (adicionar bola/obstáculo, limpar cena) para a View.
@Observable
class SimulationViewModel {
    
    /// A cena SpriteKit principal onde a simulação ocorre.
    var scene: PolyrhythmScene
    
    /// Estado de pausa da simulação. Ao ser alterado, propaga o estado para a cena.
    var isPaused: Bool = false {
        didSet {
            scene.isPausedSimulation = isPaused
        }
    }
    
    // Estado de Seleção e Edição de Notas
    var isObjectSelected: Bool = false
    var selectedNoteIndex: Int = 0 {
        didSet {
            if isObjectSelected {
                scene.updateSelectedObjectNote(index: selectedNoteIndex)
            }
        }
    }
    
    // MARK: - Estado Interno de Gestos
    
    /// Armazena o último fator de escala aplicado durante um gesto de pinça, para cálculo incremental.
    private var lastScale: CGFloat = 1.0
    
    /// Armazena o último ângulo de rotação aplicado durante um gesto, para cálculo incremental.
    private var lastRotation: Angle = .zero
    
    /// Inicializa o ViewModel e configura a cena com suas dependências.
    @MainActor
    init() {
        // Inicializa a cena com injeção de dependência do serviço de áudio
        // Definimos um tamanho padrão inicial, que será ajustado pelo .resizeFill no SwiftUI
        let audioService = SynthEngine.shared
        let newScene = PolyrhythmScene(audioService: audioService, size: CGSize(width: 300, height: 600))
        newScene.scaleMode = .resizeFill
        self.scene = newScene
        
        // Configurar Callback de Seleção
        self.scene.onObjectSelected = { [weak self] index in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let index = index {
                    self.isObjectSelected = true
                    self.selectedNoteIndex = index
                } else {
                    self.isObjectSelected = false
                }
            }
        }
        
        // Callback não é mais necessário para UI, pois usamos gestos diretos
        // self.scene.nodeSelectedCallback = ...
    }
    
    // MARK: - Gestos
    
    func handleScaleChange(scale: CGFloat) {
        let delta = scale / lastScale
        lastScale = scale
        scene.scaleSelectedNode(by: delta)
    }
    
    func handleScaleEnd() {
        lastScale = 1.0
    }
    
    func handleRotationChange(angle: Angle) {
        let delta = angle - lastRotation
        lastRotation = angle
        scene.rotateSelectedNode(by: delta.radians)
    }
    
    func handleRotationEnd() {
        lastRotation = .zero
    }
    
    func addBall() {
        scene.addBall()
    }
    
    // MARK: - Adicionar Formas
    
    func addObstacle() {
        scene.addObstacle(shape: .rectangle)
    }
    
    func addTriangle() {
        scene.addObstacle(shape: .triangle)
    }
    
    func addHexagon() {
        scene.addObstacle(shape: .hexagon)
    }
    
    func clearBalls() {
        scene.clearBalls()
    }
    
    func togglePause() {
        isPaused.toggle()
    }
}
