import SpriteKit
import SwiftUI

class PolyrhythmScene: SKScene, SKPhysicsContactDelegate {
    
    // Categorias de colisão (bitmask)
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let ball: UInt32 = 0b1       // 1
        static let wall: UInt32 = 0b10      // 2
    }
    
    override func didMove(to view: SKView) {
        // Configurações do Mundo
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        backgroundColor = .black
        
        // Define as paredes (bordas da tela)
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        borderBody.restitution = 1.0 // Perfeitamente elástico (sem perda de energia)
        borderBody.linearDamping = 0
        borderBody.angularDamping = 0
        borderBody.categoryBitMask = PhysicsCategory.wall
        borderBody.contactTestBitMask = PhysicsCategory.ball
        borderBody.collisionBitMask = PhysicsCategory.ball
        
        self.physicsBody = borderBody
    }
    
    // MARK: - Gestão de Bolas
    
    func addBall() {
        let ballRadius: CGFloat = 20
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = .cyan
        ball.strokeColor = .white
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Física da Bola
        let body = SKPhysicsBody(circleOfRadius: ballRadius)
        body.isDynamic = true
        body.categoryBitMask = PhysicsCategory.ball
        body.contactTestBitMask = PhysicsCategory.wall
        body.collisionBitMask = PhysicsCategory.wall
        body.usesPreciseCollisionDetection = true
        
        // Propriedades para manter movimento perpétuo
        body.friction = 0
        body.restitution = 1.0
        body.linearDamping = 0
        body.angularDamping = 0
        
        ball.physicsBody = body
        addChild(ball)
        
        // Impulso inicial aleatório
        let randomDx = CGFloat.random(in: -200...200)
        let randomDy = CGFloat.random(in: -200...200)
        body.velocity = CGVector(dx: randomDx, dy: randomDy)
    }
    
    func addObstacle() {
        let width = CGFloat.random(in: 80...150)
        let height = CGFloat.random(in: 20...40)
        let size = CGSize(width: width, height: height)
        
        let obstacle = SKShapeNode(rectOf: size, cornerRadius: 8)
        obstacle.fillColor = .orange
        obstacle.strokeColor = .white
        
        // Posição Aleatória (garantindo margem das bordas)
        let margin: CGFloat = 100
        let randomX = CGFloat.random(in: (frame.minX + margin)...(frame.maxX - margin))
        let randomY = CGFloat.random(in: (frame.minY + margin)...(frame.maxY - margin))
        obstacle.position = CGPoint(x: randomX, y: randomY)
        
        // Rotação aleatória
        obstacle.zRotation = CGFloat.random(in: 0...CGFloat.pi)
        
        // Física do Obstáculo
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false // Estático: não cai nem é empurrado
        body.categoryBitMask = PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.ball
        body.collisionBitMask = PhysicsCategory.ball
        
        // Propriedades de material
        body.friction = 0
        body.restitution = 1.0 // Perfeitamente elástico
        
        obstacle.physicsBody = body
        addChild(obstacle)
    }
    
    func clearBalls() {
        children.filter { $0 is SKShapeNode }.forEach { $0.removeFromParent() }
    }
    
    // MARK: - Controle de Simulação
    
    var isPausedSimulation: Bool = false {
        didSet {
            self.isPaused = isPausedSimulation
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Verifica colisão entre Bola e Parede
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Se a colisão for Bola (1) x Parede (2)
        if (firstBody.categoryBitMask & PhysicsCategory.ball != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.wall != 0) {
            
            // Feedback Sonoro
            // Frequência aleatória pentatônica para soar agradável
            let scale: [Float] = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25] // Dó Maior Pentatônica
            let randomNote = scale.randomElement() ?? 440.0
            
            SynthEngine.shared.playNote(frequency: randomNote)
            
            // TODO: Feedback Visual (ex: brilho na parede)
        }
    }
}
