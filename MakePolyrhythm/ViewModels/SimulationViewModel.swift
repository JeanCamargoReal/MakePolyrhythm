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
        // Inicializa a cena com um tamanho padrão (será redimensionada pelo SpriteView)
        // Usamos .resizeFill para que a cena ocupe todo o espaço disponível
        let newScene = PolyrhythmScene()
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
