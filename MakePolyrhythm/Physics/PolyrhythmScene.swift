import SpriteKit
import SwiftUI

// MARK: - Constants

/// Constantes globais de configuração do jogo, física e interface.
enum GameConstants {
    
    /// Configurações de Física
    enum Physics {
        static let ballCategory: UInt32 = 0b1
        static let wallCategory: UInt32 = 0b10
        static let ballRadius: CGFloat = 20.0
        /// Restituição 1.0 garante colisões perfeitamente elásticas (sem perda de energia).
        static let defaultRestitution: CGFloat = 1.0
        static let defaultFriction: CGFloat = 0.0
    }
    
    /// Configurações de Áudio
    enum Audio {
        /// Escala Pentatônica para geração de melodias harmoniosas.
        static let pentatonicScale: [Float] = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]
        static let defaultNoteDuration: Double = 0.1
    }
    
    /// Configurações de Interface e Limites
    enum UI {
        static let obstacleName = "obstacle"
        static let ballName = "ball"
        // Margens de segurança para impedir objetos sob Dynamic Island ou Home Indicator
        static let topSafeArea: CGFloat = 50.0
        static let bottomSafeArea: CGFloat = 150.0 // Maior por causa dos controles flutuantes
        static let horizontalMargin: CGFloat = 20.0
        static let verticalDragMargin: CGFloat = 50.0 // Margem vertical para o arrasto de objetos
    }
}

// MARK: - Scene

/// Cena principal do SpriteKit responsável pela simulação polirrítmica.
///
/// Implementa a lógica de:
/// - **Física**: Ambiente de gravidade zero com colisões elásticas.
/// - **Interatividade**: Seleção, arrasto (Drag), redimensionamento e rotação de objetos.
/// - **Áudio**: Disparo de sons sintetizados baseados em eventos de colisão (Bola x Parede, Bola x Bola).
class PolyrhythmScene: SKScene {
    
    // Dependências (Injeção)
    private let audioService: AudioServiceProtocol
    
    // Estado interno
    private var selectedNode: SKNode?
    
    // Estado de arrasto para cálculo de velocidade (Flick/Throw)
    private var lastTouchLocation: CGPoint?
    private var lastTouchTime: TimeInterval?
    
    /// Controla o estado de pausa da simulação física.
    var isPausedSimulation: Bool = false {
        didSet {
            self.isPaused = isPausedSimulation
        }
    }

    // MARK: - Inicialização
    
    /// Inicializa a cena com um serviço de áudio injetado.
    /// - Parameters:
    ///   - audioService: Serviço responsável pela síntese sonora.
    ///   - size: Dimensões iniciais da cena.
    init(audioService: AudioServiceProtocol, size: CGSize) {
        self.audioService = audioService
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use init(audioService:size:) instead.")
    }
    
    // MARK: - Métodos Públicos de Edição (Gestos)
    
    /// Aplica uma escala incremental ao nó selecionado.
    /// Utilizado para responder a gestos de pinça (magnification).
    /// - Parameter factor: Fator de escala a ser multiplicado pela escala atual (ex: 1.0 = sem mudança, 1.1 = +10%).
    func scaleSelectedNode(by factor: CGFloat) {
        guard let node = selectedNode else { return }
        // Aplicar escala incremental
        node.xScale *= factor
        node.yScale *= factor
    }
    
    /// Aplica uma rotação incremental ao nó selecionado.
    /// - Parameter radians: Ângulo em radianos a ser subtraído da rotação atual (ajustado para sentido do gesto).
    func rotateSelectedNode(by radians: CGFloat) {
        guard let node = selectedNode else { return }
        node.zRotation -= radians // Subtrair para acompanhar o sentido do gesto (teste prático: SwiftUI rotation é clockwise positivo? SpriteKit é counter-clockwise. Gesto: clockwise = positivo. SK: CCW = positivo. Então inverter o sinal)
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
    
    /// Configura as bordas físicas da cena.
    /// Atualmente define apenas o limite superior, permitindo que objetos saiam pelas laterais/fundo se necessário,
    /// ou pode ser configurado para fechar o loop dependendo da implementação de 'setupBorders' ativa.
    /// (Nesta versão, o código reflete um loop completo ajustado pelas margens).
    private func setupBorders() {
        let playableRect = CGRect(
            x: frame.minX,
            y: frame.minY,
            width: frame.width,
            height: frame.height - GameConstants.UI.topSafeArea
        )
        
        let borderBody = SKPhysicsBody(edgeLoopFrom: playableRect)
        borderBody.friction = GameConstants.Physics.defaultFriction
        borderBody.restitution = GameConstants.Physics.defaultRestitution
        borderBody.linearDamping = 0
        borderBody.angularDamping = 0
        borderBody.categoryBitMask = GameConstants.Physics.wallCategory
        borderBody.contactTestBitMask = GameConstants.Physics.ballCategory
        borderBody.collisionBitMask = GameConstants.Physics.ballCategory
        
        self.physicsBody = borderBody
    }
    
    // MARK: - Tipos Auxiliares
    
    enum ObstacleShape {
        case rectangle
        case triangle
        case hexagon
    }

    // MARK: - Gestão de Entidades
    
    func addBall() {
        let ball = SKShapeNode(circleOfRadius: GameConstants.Physics.ballRadius)
        ball.name = GameConstants.UI.ballName
        ball.fillColor = .cyan
        ball.strokeColor = .white
        ball.position = CGPoint(x: frame.midX, y: frame.midY)
        
        let body = SKPhysicsBody(circleOfRadius: GameConstants.Physics.ballRadius)
        body.isDynamic = true
        body.categoryBitMask = GameConstants.Physics.ballCategory
        body.contactTestBitMask = GameConstants.Physics.wallCategory | GameConstants.Physics.ballCategory
        body.collisionBitMask = GameConstants.Physics.wallCategory | GameConstants.Physics.ballCategory
        body.usesPreciseCollisionDetection = true
        
        body.friction = GameConstants.Physics.defaultFriction
        body.restitution = GameConstants.Physics.defaultRestitution
        body.linearDamping = 0
        body.angularDamping = 0
        
        ball.physicsBody = body
        addChild(ball)
        
        // Adicionar rastro
        let trail = createTrail(color: .cyan)
        trail.targetNode = self // Importante: partículas ficam no mundo, não presas à bola
        ball.addChild(trail)
        
        let randomDx = CGFloat.random(in: -200...200)
        let randomDy = CGFloat.random(in: -200...200)
        body.velocity = CGVector(dx: randomDx, dy: randomDy)
    }
    
    private func createTrail(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // Criar textura para garantir visibilidade
        emitter.particleTexture = createCircleTexture()
        
        // Configuração para Rastro Suave (Bolhas Espaçadas)
        emitter.particleBirthRate = 12 // Menos partículas para o efeito espaçado
        emitter.particleLifetime = 0.8 // Bolhas duram mais
        emitter.particlePositionRange = CGVector(dx: 5, dy: 5) // Leve espalhamento lateral
        emitter.particleAlpha = 0.5 // Opacidade inicial
        emitter.particleAlphaSpeed = -0.8 // Fade out suave e contínuo
        emitter.particleScale = 0.4 // Tamanho inicial menor
        emitter.particleScaleSpeed = -0.5 // Diminuem gradualmente
        emitter.particleRotationSpeed = CGFloat.pi * 0.5 // Giro suave
        
        // Cor e Mistura
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0 // Forçar cor sólida
        emitter.particleBlendMode = .add // Brilho aditivo ajuda em fundo preto
        
        // Física
        emitter.particleSpeed = 0
        emitter.zPosition = -1 // Atrás da bola
        
        return emitter
    }
    
    private func createCircleTexture() -> SKTexture {
        let radius: CGFloat = 10
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }
    
    func addObstacle(shape: ObstacleShape = .rectangle) {
        let obstacle: SKShapeNode
        let body: SKPhysicsBody
        
        switch shape {
        case .rectangle:
            let width = CGFloat.random(in: 80...150)
            let height = CGFloat.random(in: 20...40)
            let size = CGSize(width: width, height: height)
            
            obstacle = SKShapeNode(rectOf: size, cornerRadius: 8)
            body = SKPhysicsBody(rectangleOf: size)
            
            // Posição Aleatória (respeitando margens seguras)
            let minX = frame.minX + GameConstants.UI.horizontalMargin + (width/2)
            let maxX = frame.maxX - GameConstants.UI.horizontalMargin - (width/2)
            let minY = frame.minY + GameConstants.UI.bottomSafeArea + (height/2)
            let maxY = frame.maxY - GameConstants.UI.topSafeArea - (height/2)
            
            let safeX = minX < maxX ? CGFloat.random(in: minX...maxX) : frame.midX
            let safeY = minY < maxY ? CGFloat.random(in: minY...maxY) : frame.midY
            obstacle.position = CGPoint(x: safeX, y: safeY)
            obstacle.zRotation = CGFloat.random(in: 0...CGFloat.pi)
            
        case .triangle:
            let path = CGMutablePath()
            let side: CGFloat = 120.0
            let height = side * sqrt(3) / 2
            // Triângulo equilátero centrado
            path.move(to: CGPoint(x: 0, y: height/2))
            path.addLine(to: CGPoint(x: side/2, y: -height/2))
            path.addLine(to: CGPoint(x: -side/2, y: -height/2))
            path.closeSubpath()
            
            obstacle = SKShapeNode(path: path)
            body = SKPhysicsBody(polygonFrom: path)
            obstacle.position = CGPoint(x: frame.midX, y: frame.midY)
            
        case .hexagon:
            let path = CGMutablePath()
            let radius: CGFloat = 70.0
            for i in 0..<6 {
                let angle = CGFloat(i) * (2 * CGFloat.pi / 6)
                let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            
            obstacle = SKShapeNode(path: path)
            body = SKPhysicsBody(polygonFrom: path)
            obstacle.position = CGPoint(x: frame.midX, y: frame.midY)
        }
        
        // Configurações Comuns
        obstacle.name = GameConstants.UI.obstacleName
        obstacle.fillColor = .orange
        obstacle.strokeColor = .white
        obstacle.lineWidth = 2
        
        body.isDynamic = false
        body.categoryBitMask = GameConstants.Physics.wallCategory
        body.contactTestBitMask = GameConstants.Physics.ballCategory
        body.collisionBitMask = GameConstants.Physics.ballCategory | GameConstants.Physics.wallCategory
        
        body.friction = GameConstants.Physics.defaultFriction
        body.restitution = GameConstants.Physics.defaultRestitution
        
        obstacle.physicsBody = body
        addChild(obstacle)
    }
    
    func clearBalls() {
        children.forEach { $0.removeFromParent() }
    }
    
    // MARK: - Touch Handling
    
    /// Detecta o início de um toque para selecionar obstáculos ou pegar bolas.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Prioridade 1: Obstáculos (Edição)
        if let obstacleNode = touchedNodes.first(where: { $0.name == GameConstants.UI.obstacleName }) {
            selectNode(obstacleNode, isBall: false)
            obstacleNode.physicsBody?.angularVelocity = 0
            
        // Prioridade 2: Bolas (Interação Física)
        } else if let ballNode = touchedNodes.first(where: { $0.name == GameConstants.UI.ballName }) {
            selectNode(ballNode, isBall: true)
            
            // Preparar para arrasto físico
            ballNode.physicsBody?.isDynamic = false // "Pegar na mão"
            ballNode.physicsBody?.velocity = .zero
            
            // Iniciar rastreamento para cálculo de arremesso
            lastTouchLocation = location
            lastTouchTime = touch.timestamp
            
        } else {
            // Tocou no fundo -> Deselecionar se houver seleção anterior
            deselectCurrentNode()
        }
    }
    
    /// Manipula o arrasto de objetos.
    /// - Para obstáculos: Move e restringe às margens.
    /// - Para bolas: Move livremente (ou restrito) e rastreia velocidade para lançamento.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = selectedNode else { return }
        let location = touch.location(in: self)
        
        // Clamp de segurança (vale para ambos para não perder objetos fora da tela)
        let hMargin = GameConstants.UI.horizontalMargin
        let vMargin = GameConstants.UI.verticalDragMargin
        
        let minX = frame.minX + hMargin
        let maxX = frame.maxX - hMargin
        let minY = frame.minY + vMargin
        let maxY = frame.maxY - vMargin
        
        let clampedX = min(max(location.x, minX), maxX)
        let clampedY = min(max(location.y, minY), maxY)
        let newPosition = CGPoint(x: clampedX, y: clampedY)
        
        node.position = newPosition
        
        // Se for bola, atualizamos o rastreamento para o arremesso
        if node.name == GameConstants.UI.ballName {
            // A velocidade instantânea será calculada no final, mas precisamos manter o último ponto válido
            // Poderíamos fazer média móvel aqui, mas lastTouchLocation basta para flick simples.
            // Atualizamos a cada move para ter o vetor do último frame
            // Nota: Se movermos muito rápido, o touch pode pular.
        }
    }
    
    /// Finaliza a interação.
    /// - Para bolas: Calcula a velocidade de lançamento e reativa a física.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = selectedNode else { return }
        
        if node.name == GameConstants.UI.ballName {
            // Lógica de Arremesso (Flick)
            let currentLocation = touch.location(in: self)
            let currentTime = touch.timestamp
            
            // Reativar física
            node.physicsBody?.isDynamic = true
            
            if let lastPos = lastTouchLocation, let lastTime = lastTouchTime {
                let dt = currentTime - lastTime
                
                // Evitar divisão por zero ou dt muito grande (toque parado)
                if dt > 0 && dt < 0.2 {
                    // Calcular vetor velocidade: distancia / tempo
                    let dx = currentLocation.x - lastPos.x
                    let dy = currentLocation.y - lastPos.y
                    
                    // Fator de sensibilidade (ajuste fino para sensação de "força")
                    let sensitivity: CGFloat = 1.0 // 1.0 é fisicamente "real" se dt for preciso em segundos
                    // Como dt é pequeno, dx/dt gera velocidade em points/s.
                    // SKPhysicsBody.velocity é points/s.
                    
                    let velocity = CGVector(dx: dx / CGFloat(dt) * sensitivity, dy: dy / CGFloat(dt) * sensitivity)
                    
                    // Aplicar velocidade (com limite máximo para evitar explosão física)
                    let maxVelocity: CGFloat = 2000.0
                    let clampedDx = min(max(velocity.dx, -maxVelocity), maxVelocity)
                    let clampedDy = min(max(velocity.dy, -maxVelocity), maxVelocity)
                    
                    node.physicsBody?.velocity = CGVector(dx: clampedDx, dy: clampedDy)
                } else {
                    // Se segurou muito tempo parado, solta com velocidade zero
                    node.physicsBody?.velocity = .zero
                }
            }
            
            // Limpar seleção de bola (não queremos editar bolas via UI de gestos depois de jogar)
            deselectCurrentNode()
            lastTouchLocation = nil
            lastTouchTime = nil
        }
        
        // Para obstáculos, mantemos selecionado (comportamento original)
    }
    
    // MARK: - Helpers de Seleção
    
    private func selectNode(_ node: SKNode, isBall: Bool) {
        // Se já havia outro selecionado, restaura
        if let prev = selectedNode, prev != node {
            restoreNodeVisuals(prev)
        }
        
        selectedNode = node
        
        // Feedback visual (Apenas Alpha para preservar escala do usuário)
        let fade = SKAction.fadeAlpha(to: 0.6, duration: 0.1) // Mais transparente para indicar "em edição" ou "segurando"
        node.run(fade)
    }
    
    private func deselectCurrentNode() {
        guard let node = selectedNode else { return }
        restoreNodeVisuals(node)
        selectedNode = nil
    }
    
    private func restoreNodeVisuals(_ node: SKNode) {
        // Restaurar visual original
        let fadeBack = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        node.run(fadeBack)
    }
    
    // MARK: - Feedback Visual
    
    /// Aciona um flash visual no nó (brilho branco rápido).
    private func triggerVisualFeedback(_ node: SKNode) {
        guard let shapeNode = node as? SKShapeNode else { return }
        
        // Determinar cor original baseada no tipo, para evitar bug de capturar "branco" durante flashes repetidos
        let targetColor: UIColor
        if node.name == GameConstants.UI.ballName {
            targetColor = .cyan
        } else if node.name == GameConstants.UI.obstacleName {
            targetColor = .orange
        } else {
            targetColor = shapeNode.fillColor // Fallback
        }
        
        // Remove ações anteriores de flash para evitar conflito de cores
        shapeNode.removeAction(forKey: "flash")
        
        shapeNode.fillColor = .white
        
        let wait = SKAction.wait(forDuration: 0.05)
        let restore = SKAction.run {
            shapeNode.fillColor = targetColor
        }
        let sequence = SKAction.sequence([wait, restore])
        
        shapeNode.run(sequence, withKey: "flash")
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
            if let wallNode = secondBody.node {
                triggerVisualFeedback(wallNode)
            }
        }
        // Colisão Bola (1) x Bola (1)
        else if (firstBody.categoryBitMask & GameConstants.Physics.ballCategory != 0) &&
                (secondBody.categoryBitMask & GameConstants.Physics.ballCategory != 0) {
            
            playBallCollisionSound()
            if let ball1 = firstBody.node { triggerVisualFeedback(ball1) }
            if let ball2 = secondBody.node { triggerVisualFeedback(ball2) }
        }
    }
    
    private func playRandomNote() {
        let randomNote = GameConstants.Audio.pentatonicScale.randomElement() ?? 440.0
        audioService.playNote(frequency: randomNote, duration: GameConstants.Audio.defaultNoteDuration)
    }
    
    private func playBallCollisionSound() {
        // Usa a mesma escala para harmonia, mas com o timbre percussivo específico
        let randomNote = GameConstants.Audio.pentatonicScale.randomElement() ?? 440.0
        audioService.playBallCollision(frequency: randomNote)
    }
}