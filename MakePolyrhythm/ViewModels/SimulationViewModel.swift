import SwiftUI
import SpriteKit
import Observation

@Observable
class SimulationViewModel {
    var scene: PolyrhythmScene
    var isPaused: Bool = false {
        didSet {
            scene.isPausedSimulation = isPaused
        }
    }
    
    // Estado interno para gestos
    private var lastScale: CGFloat = 1.0
    private var lastRotation: Angle = .zero
    
    @MainActor
    init() {
        // Inicializa a cena com injeção de dependência do serviço de áudio
        // Definimos um tamanho padrão inicial, que será ajustado pelo .resizeFill no SwiftUI
        let audioService = SynthEngine.shared
        let newScene = PolyrhythmScene(audioService: audioService, size: CGSize(width: 300, height: 600))
        newScene.scaleMode = .resizeFill
        self.scene = newScene
        
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
    
    func addObstacle() {
        scene.addObstacle()
    }
    
    func clearBalls() {
        scene.clearBalls()
    }
    
    func togglePause() {
        isPaused.toggle()
    }
}
