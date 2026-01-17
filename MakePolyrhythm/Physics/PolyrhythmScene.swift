import SpriteKit
import SwiftUI

// MARK: - Constants

enum GameConstants {
    enum Physics {
        static let ballCategory: UInt32 = 0b1
        static let wallCategory: UInt32 = 0b10
        static let ballRadius: CGFloat = 20.0
        static let defaultRestitution: CGFloat = 1.0
        static let defaultFriction: CGFloat = 0.0
    }
    
    enum Audio {
        static let pentatonicScale: [Float] = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]
        static let defaultNoteDuration: Double = 0.1
    }
    
    enum UI {
        static let obstacleName = "obstacle"
    }
}

// MARK: - Scene

class PolyrhythmScene: SKScene {
    
    // Dependências (Injeção)
    private let audioService: AudioServiceProtocol
    
    // Estado interno
    private var selectedNode: SKNode?
    
    var isPausedSimulation: Bool = false {
        didSet {
            self.isPaused = isPausedSimulation
        }
    }

    // MARK: - Inicialização
    
    init(audioService: AudioServiceProtocol, size: CGSize) {
        self.audioService = audioService
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(audioService:size:) instead.")
    }
    
    // MARK: - Ciclo de Vida
    
    override func didMove(to view: SKView) {
        setupPhysicsWorld()
        setupBackground()
        setupBorders()
    }
    
    // MARK: - Setup
    
    private func setupPhysicsWorld() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    private func setupBackground() {
        backgroundColor = .black
    }
    
    private func setupBorders() {
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = GameConstants.Physics.defaultFriction
        borderBody.restitution = GameConstants.Physics.defaultRestitution
        borderBody.linearDamping = 0
        borderBody.angularDamping = 0
        borderBody.categoryBitMask = GameConstants.Physics.wallCategory
        borderBody.contactTestBitMask = GameConstants.Physics.ballCategory
        borderBody.collisionBitMask = GameConstants.Physics.ballCategory
        
        self.physicsBody = borderBody
    }
    
    // MARK: - Gestão de Entidades
    
    func addBall() {
        let ball = SKShapeNode(circleOfRadius: GameConstants.Physics.ballRadius)
        ball.fillColor = .cyan
        ball.strokeColor = .white
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        
        let body = SKPhysicsBody(circleOfRadius: GameConstants.Physics.ballRadius)
        body.isDynamic = true
        body.categoryBitMask = GameConstants.Physics.ballCategory
        body.contactTestBitMask = GameConstants.Physics.wallCategory
        body.collisionBitMask = GameConstants.Physics.wallCategory
        body.usesPreciseCollisionDetection = true
        
        body.friction = GameConstants.Physics.defaultFriction
        body.restitution = GameConstants.Physics.defaultRestitution
        body.linearDamping = 0
        body.angularDamping = 0
        
        ball.physicsBody = body
        addChild(ball)
        
        let randomDx = CGFloat.random(in: -200...200)
        let randomDy = CGFloat.random(in: -200...200)
        body.velocity = CGVector(dx: randomDx, dy: randomDy)
    }
    
    func addObstacle() {
        let width = CGFloat.random(in: 80...150)
        let height = CGFloat.random(in: 20...40)
        let size = CGSize(width: width, height: height)
        
        let obstacle = SKShapeNode(rectOf: size, cornerRadius: 8)
        obstacle.name = GameConstants.UI.obstacleName
        obstacle.fillColor = .orange
        obstacle.strokeColor = .white
        
        let margin: CGFloat = 100
        let randomX = CGFloat.random(in: (frame.minX + margin)...(frame.maxX - margin))
        let randomY = CGFloat.random(in: (frame.minY + margin)...(frame.maxY - margin))
        obstacle.position = CGPoint(x: randomX, y: randomY)
        obstacle.zRotation = CGFloat.random(in: 0...CGFloat.pi)
        
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.categoryBitMask = GameConstants.Physics.wallCategory
        body.contactTestBitMask = GameConstants.Physics.ballCategory
        body.collisionBitMask = GameConstants.Physics.ballCategory
        
        body.friction = GameConstants.Physics.defaultFriction
        body.restitution = GameConstants.Physics.defaultRestitution
        
        obstacle.physicsBody = body
        addChild(obstacle)
    }
    
    func clearBalls() {
        children.forEach { $0.removeFromParent() }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        if let obstacleNode = touchedNodes.first(where: { $0.name == GameConstants.UI.obstacleName }) {
            selectedNode = obstacleNode
            
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
            let fade = SKAction.fadeAlpha(to: 0.8, duration: 0.1)
            obstacleNode.run(SKAction.group([scaleUp, fade]))
            
            obstacleNode.physicsBody?.angularVelocity = 0
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = selectedNode else { return }
        node.position = touch.location(in: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let node = selectedNode else { return }
        
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fadeBack = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        node.run(SKAction.group([scaleDown, fadeBack]))
        
        selectedNode = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

// MARK: - SKPhysicsContactDelegate

extension PolyrhythmScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Colisão Bola (1) x Parede (2)
        if (firstBody.categoryBitMask & GameConstants.Physics.ballCategory != 0) &&
            (secondBody.categoryBitMask & GameConstants.Physics.wallCategory != 0) {
            
            playRandomNote()
        }
    }
    
    private func playRandomNote() {
        let randomNote = GameConstants.Audio.pentatonicScale.randomElement() ?? 440.0
        audioService.playNote(frequency: randomNote, duration: GameConstants.Audio.defaultNoteDuration)
    }
}