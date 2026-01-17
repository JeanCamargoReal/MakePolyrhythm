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
    
    @MainActor
    init() {
        // Inicializa a cena com injeção de dependência do serviço de áudio
        // Definimos um tamanho padrão inicial, que será ajustado pelo .resizeFill no SwiftUI
        let audioService = SynthEngine.shared
        let newScene = PolyrhythmScene(audioService: audioService, size: CGSize(width: 300, height: 600))
        newScene.scaleMode = .resizeFill
        self.scene = newScene
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
