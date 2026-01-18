import SwiftUI
import SpriteKit
import Observation

/// ViewModel responsável pela lógica de apresentação e controle da simulação física 2D.
///
/// Atua como uma ponte (Bridge) entre a interface SwiftUI e a cena SpriteKit.
/// Gerencia:
/// - O estado global da simulação (Pausa/Play).
/// - A seleção de objetos e edição de suas propriedades (Notas).
/// - A tradução de comandos da UI para ações na Cena.
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
    
    // MARK: - Estado de Seleção
    
    /// Indica se há um objeto (obstáculo) selecionado na cena para edição.
    var isObjectSelected: Bool = false
    
    /// Índice da nota musical configurada para o objeto selecionado.
    /// Ao ser alterado via UI, atualiza imediatamente a propriedade na cena.
    var selectedNoteIndex: Int = 0 {
        didSet {
            if isObjectSelected {
                scene.updateSelectedObjectNote(index: selectedNoteIndex)
            }
        }
    }
    
    // Variáveis internas para cálculo incremental de gestos
    private var lastScale: CGFloat = 1.0
    private var lastRotation: Angle = .zero
    
    /// Inicializa o ViewModel, cria a cena e configura os callbacks de interação.
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
                // Envolver em withAnimation para suavizar a transição da UI
                withAnimation {
                    if let index = index {
                        self.isObjectSelected = true
                        self.selectedNoteIndex = index
                    } else {
                        self.isObjectSelected = false
                    }
                }
            }
        }
    }
    
    // MARK: - Gestos
    
    /// Manipula a mudança de escala de um gesto de pinça.
    /// - Parameter scale: O valor de escala reportado pelo gesto.
    func handleScaleChange(scale: CGFloat) {
        let delta = scale / lastScale
        lastScale = scale
        scene.scaleSelectedNode(by: delta)
    }
    
    /// Finaliza o gesto de escala, resetando o estado interno.
    func handleScaleEnd() {
        lastScale = 1.0
    }
    
    /// Manipula a mudança de rotação de um gesto.
    /// - Parameter angle: O valor de ângulo reportado pelo gesto.
    func handleRotationChange(angle: Angle) {
        let delta = angle - lastRotation
        lastRotation = angle
        scene.rotateSelectedNode(by: delta.radians)
    }
    
    /// Finaliza o gesto de rotação, resetando o estado interno.
    func handleRotationEnd() {
        lastRotation = .zero
    }
    
    // MARK: - Ações
    
    /// Adiciona uma nova bola à cena.
    func addBall() {
        scene.addBall()
    }
    
    /// Adiciona um obstáculo retangular padrão à cena.
    func addObstacle() { // Default to rectangle
        scene.addObstacle(shape: .rectangle)
    }
    
    /// Adiciona um obstáculo triangular à cena.
    func addTriangle() {
        scene.addObstacle(shape: .triangle)
    }
    
    /// Adiciona um obstáculo hexagonal à cena.
    func addHexagon() {
        scene.addObstacle(shape: .hexagon)
    }
    
    /// Adiciona um obstáculo em formato de losango à cena.
    func addDiamond() {
        scene.addObstacle(shape: .diamond)
    }
    
    /// Remove todas as bolas da cena.
    func clearBalls() {
        scene.clearBalls()
    }
    
    /// Alterna o estado de pausa da simulação (Play/Pause).
    func togglePause() {
        isPaused.toggle()
    }
}