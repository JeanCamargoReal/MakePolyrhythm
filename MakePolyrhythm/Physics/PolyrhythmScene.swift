import SpriteKit
import SwiftUI

// MARK: - Constants

/// Constantes globais de configuração do jogo, física e interface.
enum GameConstants {
    
    /// Configurações de Física e Máscaras de Colisão.
    enum Physics {
        /// Categoria para Bolas (Dinâmicas).
        static let ballCategory: UInt32 = 0b1
        /// Categoria para Paredes/Obstáculos (Estáticos).
        static let wallCategory: UInt32 = 0b10
        
        static let ballRadius: CGFloat = 20.0
        /// Restituição 1.0 garante colisões perfeitamente elásticas (sem perda de energia).
        static let defaultRestitution: CGFloat = 1.0
        static let defaultFriction: CGFloat = 0.0
    }
    
    /// Configurações de Áudio e Música.
    enum Audio {
        /// Escala Harmônica (Lídio) estendida para sons etéreos e polifonia rica.
        static let harmonicScale: [Float] = [
            261.63, 293.66, 329.63, 369.99, 392.00, 440.00, 493.88, // Oitava 4
            523.25, 587.33, 659.25, 739.99, 783.99, 880.00, 987.77  // Oitava 5
        ]
        static let defaultNoteDuration: Double = 0.1
    }
    
    /// Configurações de Interface e Limites de Segurança.
    enum UI {
        static let obstacleName = "obstacle"
        static let ballName = "ball"
        // Margens para impedir que objetos fiquem sob a Dynamic Island ou Home Indicator
        static let topSafeArea: CGFloat = 50.0
        static let bottomSafeArea: CGFloat = 150.0
        static let horizontalMargin: CGFloat = 20.0
        static let verticalDragMargin: CGFloat = 50.0
    }
}

// MARK: - Scene

/// Cena principal do SpriteKit onde ocorre a simulação polirrítmica.
///
/// Esta classe é responsável por:
/// 1.  **Física:** Configurar o mundo (gravidade zero), bordas e corpos físicos.
/// 2.  **Entidades:** Gerenciar a criação de bolas e obstáculos com texturas procedurais vibrantes.
/// 3.  **Interação:** Lidar com toques (seleção, arrasto, lançamento) e gestos.
/// 4.  **Áudio/Visual:** Disparar sons e feedbacks visuais (flash, pulso) baseados em colisões.
class PolyrhythmScene: SKScene {
    
    // Dependências (Injeção)
    private let audioService: AudioServiceProtocol
    
    // Estado interno da Cena
    private var selectedNode: SKNode?
    
    /// Callback acionado quando um objeto é selecionado, passando o índice da sua nota (ou nil).
    var onObjectSelected: ((Int?) -> Void)?
    
    // Variáveis para cálculo de velocidade de lançamento (Flick)
    private var lastTouchLocation: CGPoint?
    private var lastTouchTime: TimeInterval?
    
    /// Controla o estado de pausa da simulação física (congela o tempo).
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
        case diamond
    }

    // MARK: - Gestão de Entidades
    
    /// Adiciona uma nova bola à cena com textura de gradiente radial e física dinâmica.
    func addBall() {
        let ball = SKShapeNode(circleOfRadius: GameConstants.Physics.ballRadius)
        ball.name = GameConstants.UI.ballName
        
        // Estilo Vibrante 2D: Gera textura em tempo real
        let texture = createRadialGradientTexture(color: .cyan, radius: GameConstants.Physics.ballRadius)
        ball.fillTexture = texture
        ball.fillColor = .white // Base branca para não tingir a textura
        ball.strokeColor = .clear
        ball.blendMode = .alpha
        
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
        
        // Adiciona rastro de partículas
        let trail = createTrail(color: .cyan)
        trail.targetNode = self
        ball.addChild(trail)
        
        let randomDx = CGFloat.random(in: -200...200)
        let randomDy = CGFloat.random(in: -200...200)
        body.velocity = CGVector(dx: randomDx, dy: randomDy)
    }
    
    /// Cria um sistema de partículas (rastro) suave estilo "bolhas".
    private func createTrail(color: UIColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // Criar textura para garantir visibilidade
        emitter.particleTexture = createCircleTexture()
        
        // Configuração para Rastro Suave (Bolhas Espaçadas)
        emitter.particleBirthRate = 12
        emitter.particleLifetime = 0.8
        emitter.particlePositionRange = CGVector(dx: 5, dy: 5)
        emitter.particleAlpha = 0.5
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 0.4
        emitter.particleScaleSpeed = -0.5
        emitter.particleRotationSpeed = CGFloat.pi * 0.5
        
        // Cor e Mistura
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0
        emitter.particleBlendMode = .add
        
        // Física
        emitter.particleSpeed = 0
        emitter.zPosition = -1
        
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
    
    /// Gera uma textura de gradiente radial vibrante para bolas (Estilo 2D Moderno).
    private func createRadialGradientTexture(color: UIColor, radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let ctx = context.cgContext
            let center = CGPoint(x: radius, y: radius)
            
            // Gradiente Radial: Centro (Branco/Cor Clara) -> Borda (Cor Base Saturada)
            let colors = [UIColor.white.withAlphaComponent(0.9).cgColor, color.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
            }
            
            // Borda fina para definição
            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(2.0)
            ctx.strokeEllipse(in: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1))
        }
        
        return SKTexture(image: image)
    }
    
    /// Gera uma textura de gradiente linear para obstáculos (Retângulo/Hexágono).
    private func createLinearGradientTexture(path: CGPath, color: UIColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let ctx = context.cgContext
            let pathBounds = path.boundingBox
            
            ctx.translateBy(x: -pathBounds.minX, y: -pathBounds.minY)
            
            // Clipar pelo path
            ctx.addPath(path)
            ctx.clip()
            
            // Gradiente Linear Diagonal
            let colors = [UIColor.white.withAlphaComponent(0.4).cgColor, color.cgColor] as CFArray
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                let start = CGPoint(x: pathBounds.minX, y: pathBounds.minY)
                let end = CGPoint(x: pathBounds.maxX, y: pathBounds.maxY)
                ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
            }
        }
        
        return SKTexture(image: image)
    }
    
    /// Gera uma textura de gradiente vertical para triângulos.
    private func createVerticalGradientTexture(path: CGPath, color: UIColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let ctx = context.cgContext
            let pathBounds = path.boundingBox
            
            ctx.translateBy(x: -pathBounds.minX, y: -pathBounds.minY)
            
            ctx.addPath(path)
            ctx.clip()
            
            // Gradiente Linear Vertical: Topo (Claro) -> Base (Cor Sólida)
            let colors = [UIColor.white.withAlphaComponent(0.6).cgColor, color.cgColor] as CFArray
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                let start = CGPoint(x: pathBounds.midX, y: 0) // Topo da imagem
                let end = CGPoint(x: pathBounds.midX, y: size.height) // Base da imagem
                ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
            }
        }
        
        return SKTexture(image: image)
    }
    
    /// Gera uma textura de gradiente radial para polígonos (Diamond).
    private func createRadialGradientTextureForPolygon(path: CGPath, color: UIColor, size: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let ctx = context.cgContext
            let pathBounds = path.boundingBox
            let center = CGPoint(x: pathBounds.midX, y: pathBounds.midY)
            let maxRadius = max(pathBounds.width, pathBounds.height) / 2
            
            ctx.translateBy(x: -pathBounds.minX, y: -pathBounds.minY)
            
            ctx.addPath(path)
            ctx.clip()
            
            // Gradiente Radial
            let colors = [UIColor.white.withAlphaComponent(0.6).cgColor, color.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: maxRadius, options: [])
            }
        }
        
        return SKTexture(image: image)
    }
    
    /// Adiciona um obstáculo à cena com a forma especificada (Retângulo, Triângulo, Hexágono, Losango).
    func addObstacle(shape: ObstacleShape = .rectangle) {
        let obstacle: SKShapeNode
        let body: SKPhysicsBody
        let path: CGPath
        
        switch shape {
        case .rectangle:
            let width = CGFloat.random(in: 80...150)
            let height = CGFloat.random(in: 20...40)
            let rect = CGRect(x: -width/2, y: -height/2, width: width, height: height)
            path = CGPath(rect: rect, transform: nil) // Cantos agudos
            obstacle = SKShapeNode(path: path)
            body = SKPhysicsBody(rectangleOf: CGSize(width: width, height: height))
            
            // Posição
            let minX = frame.minX + GameConstants.UI.horizontalMargin + (width/2)
            let maxX = frame.maxX - GameConstants.UI.horizontalMargin - (width/2)
            let minY = frame.minY + GameConstants.UI.bottomSafeArea + (height/2)
            let maxY = frame.maxY - GameConstants.UI.topSafeArea - (height/2)
            let safeX = minX < maxX ? CGFloat.random(in: minX...maxX) : frame.midX
            let safeY = minY < maxY ? CGFloat.random(in: minY...maxY) : frame.midY
            obstacle.position = CGPoint(x: safeX, y: safeY)
            obstacle.zRotation = CGFloat.random(in: 0...CGFloat.pi)
            
        case .triangle:
            let mutablePath = CGMutablePath()
            let baseSide: CGFloat = 100.0 // Lado da base do triângulo
            let triHeight = baseSide * sqrt(3) / 2 // Altura de um triângulo equilátero
            
            mutablePath.move(to: CGPoint(x: 0, y: triHeight / 2)) // Vértice superior
            mutablePath.addLine(to: CGPoint(x: -baseSide / 2, y: -triHeight / 2)) // Canto inferior esquerdo
            mutablePath.addLine(to: CGPoint(x: baseSide / 2, y: -triHeight / 2)) // Canto inferior direito
            mutablePath.closeSubpath()
            path = mutablePath
            obstacle = SKShapeNode(path: path)
            body = SKPhysicsBody(polygonFrom: path)
            obstacle.position = CGPoint(x: frame.midX, y: frame.midY)
            
        case .hexagon:
            let mutablePath = CGMutablePath()
            let radius: CGFloat = 70.0
            for i in 0..<6 {
                let angle = CGFloat(i) * (2 * CGFloat.pi / 6)
                let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
                if i == 0 { mutablePath.move(to: point) } else { mutablePath.addLine(to: point) }
            }
            mutablePath.closeSubpath()
            path = mutablePath
            obstacle = SKShapeNode(path: path)
            body = SKPhysicsBody(polygonFrom: path)
            obstacle.position = CGPoint(x: frame.midX, y: frame.midY)
            
        case .diamond:
            let mutablePath = CGMutablePath()
            let diamondWidth: CGFloat = 80.0
            let diamondHeight: CGFloat = 120.0
            
            mutablePath.move(to: CGPoint(x: 0, y: diamondHeight / 2)) // Topo
            mutablePath.addLine(to: CGPoint(x: diamondWidth / 2, y: 0)) // Direita
            mutablePath.addLine(to: CGPoint(x: 0, y: -diamondHeight / 2)) // Base
            mutablePath.addLine(to: CGPoint(x: -diamondWidth / 2, y: 0)) // Esquerda
            mutablePath.closeSubpath()
            path = mutablePath
            obstacle = SKShapeNode(path: path)
            body = SKPhysicsBody(polygonFrom: path)
            obstacle.position = CGPoint(x: frame.midX, y: frame.midY)
        }
        
        // Configurações Comuns (Vibrante 2D)
        obstacle.name = GameConstants.UI.obstacleName
        
        let texture: SKTexture
        if shape == .triangle {
            texture = createVerticalGradientTexture(path: path, color: .orange, size: path.boundingBox.size)
        } else if shape == .rectangle || shape == .hexagon {
            texture = createLinearGradientTexture(path: path, color: .orange, size: path.boundingBox.size)
        } else { // Diamond (Radial ou Linear? Vamos de Radial ajustado ou Linear)
            // Diamond fica bem com Radial se for bem feito, ou linear vertical. Vamos usar Radial existente para variar.
            texture = createRadialGradientTextureForPolygon(path: path, color: .orange, size: path.boundingBox.size)
        }
        
        obstacle.fillTexture = texture
        obstacle.fillColor = .white
        obstacle.strokeColor = .white // Borda uniforme vetorial
        obstacle.lineWidth = 2.0
        obstacle.blendMode = .alpha
        
        body.isDynamic = false
        body.categoryBitMask = GameConstants.Physics.wallCategory
        body.contactTestBitMask = GameConstants.Physics.ballCategory
        body.collisionBitMask = GameConstants.Physics.ballCategory | GameConstants.Physics.wallCategory
        body.friction = GameConstants.Physics.defaultFriction
        body.restitution = GameConstants.Physics.defaultRestitution
        
        obstacle.physicsBody = body
        
        // Atribuir nota inicial aleatória
        let randomNoteIndex = Int.random(in: 0..<GameConstants.Audio.harmonicScale.count)
        obstacle.userData = ["noteIndex": randomNoteIndex]
        
        addChild(obstacle)
    }
    
    // MARK: - Configuração de Notas
    
    func updateSelectedObjectNote(index: Int) {
        guard let node = selectedNode else { return }
        
        // Validar índice
        let scale = GameConstants.Audio.harmonicScale
        guard index >= 0 && index < scale.count else { return }
        
        // Salvar
        if node.userData == nil { node.userData = [:] }
        node.userData?["noteIndex"] = index
        
        // Feedback sonoro (Preview)
        audioService.playNote(frequency: scale[index], duration: 0.2)
        
        // Feedback visual (Flash rápido na cor da nota? Opcional, por enquanto mantemos o flash branco padrão)
        triggerVisualFeedback(node)
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
            selectNode(obstacleNode, isBall: false)
            obstacleNode.physicsBody?.angularVelocity = 0
            
        } else if let ballNode = touchedNodes.first(where: { $0.name == GameConstants.UI.ballName }) {
            selectNode(ballNode, isBall: true)
            ballNode.physicsBody?.isDynamic = false
            ballNode.physicsBody?.velocity = .zero
            lastTouchLocation = location
            lastTouchTime = touch.timestamp
            
        } else {
            deselectCurrentNode()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = selectedNode else { return }
        let location = touch.location(in: self)
        
        let hMargin = GameConstants.UI.horizontalMargin
        let vMargin = GameConstants.UI.verticalDragMargin
        
        let minX = frame.minX + hMargin
        let maxX = frame.maxX - hMargin
        let minY = frame.minY + vMargin
        let maxY = frame.maxY - vMargin
        
        let clampedX = min(max(location.x, minX), maxX)
        let clampedY = min(max(location.y, minY), maxY)
        
        node.position = CGPoint(x: clampedX, y: clampedY)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = selectedNode else { return }
        
        if node.name == GameConstants.UI.ballName {
            let currentLocation = touch.location(in: self)
            let currentTime = touch.timestamp
            node.physicsBody?.isDynamic = true
            
            if let lastPos = lastTouchLocation, let lastTime = lastTouchTime {
                let dt = currentTime - lastTime
                if dt > 0 && dt < 0.2 {
                    let dx = currentLocation.x - lastPos.x
                    let dy = currentLocation.y - lastPos.y
                    let sensitivity: CGFloat = 1.0
                    let velocity = CGVector(dx: dx / CGFloat(dt) * sensitivity, dy: dy / CGFloat(dt) * sensitivity)
                    
                    let maxVelocity: CGFloat = 2000.0
                    let clampedDx = min(max(velocity.dx, -maxVelocity), maxVelocity)
                    let clampedDy = min(max(velocity.dy, -maxVelocity), maxVelocity)
                    
                    node.physicsBody?.velocity = CGVector(dx: clampedDx, dy: clampedDy)
                } else {
                    node.physicsBody?.velocity = .zero
                }
            }
            deselectCurrentNode()
            lastTouchLocation = nil
            lastTouchTime = nil
        }
    }
    
    // MARK: - Helpers de Seleção
    
    private func selectNode(_ node: SKNode, isBall: Bool) {
        if let prev = selectedNode, prev != node {
            restoreNodeVisuals(prev)
        }
        selectedNode = node
        let fade = SKAction.fadeAlpha(to: 0.6, duration: 0.1)
        node.run(fade)
        
        // Notificar UI sobre a nota do objeto selecionado
        if !isBall {
            let index = node.userData?["noteIndex"] as? Int ?? 0
            onObjectSelected?(index)
        } else {
            onObjectSelected?(nil)
        }
    }
    
    private func deselectCurrentNode() {
        guard let node = selectedNode else { return }
        restoreNodeVisuals(node)
        selectedNode = nil
        onObjectSelected?(nil)
    }
    
    private func restoreNodeVisuals(_ node: SKNode) {
        let fadeBack = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        node.run(fadeBack)
    }
    
    // MARK: - Feedback Visual
    
    private func triggerVisualFeedback(_ node: SKNode) {
        guard let shapeNode = node as? SKShapeNode else { return }
        
        let targetColor: UIColor
        if node.name == GameConstants.UI.ballName {
            targetColor = .cyan
        } else if node.name == GameConstants.UI.obstacleName {
            targetColor = .orange
        } else {
            targetColor = shapeNode.fillColor
        }
        
        // Remove ações anteriores de pulso do nó pai
        shapeNode.removeAction(forKey: "pulse")
        // Remove overlays antigos se houver
        shapeNode.childNode(withName: "flashOverlay")?.removeFromParent()
        
        // 1. Criar Overlay para a cor (garante que a cor apareça sobre a textura)
        let overlay: SKShapeNode
        if let path = shapeNode.path {
            overlay = SKShapeNode(path: path)
        } else {
            overlay = SKShapeNode(circleOfRadius: shapeNode.frame.width / 2)
        }
        
        overlay.name = "flashOverlay"
        overlay.strokeColor = .clear
        overlay.zPosition = 1 // Em cima da textura original
        overlay.alpha = 0.8   // Leve transparência para misturar
        
        shapeNode.addChild(overlay)
        
        // 2. Animação de Cores no Overlay (Ciclo Arco-íris)
        let rainbowColors: [UIColor] = [.magenta, .blue, .cyan, .green, .yellow, .red, .white]
        let duration: TimeInterval = 0.4
        let stepDuration = duration / TimeInterval(rainbowColors.count)
        
        var colorActions: [SKAction] = []
        for color in rainbowColors {
            colorActions.append(SKAction.run { overlay.fillColor = color })
            colorActions.append(SKAction.wait(forDuration: stepDuration))
        }
        let colorSequence = SKAction.sequence(colorActions)
        
        // Fade out e remover overlay
        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let remove = SKAction.removeFromParent()
        let overlaySequence = SKAction.sequence([colorSequence, fadeOut, remove])
        
        overlay.run(overlaySequence)
        
        // 3. Animação de Pulso no Nó Pai (Impacto Físico)
        let scaleUp = SKAction.scale(to: 1.15, duration: 0.05)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.35)
        let pulseSequence = SKAction.sequence([scaleUp, scaleDown])
        
        shapeNode.run(pulseSequence, withKey: "pulse")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    private func playRandomNote() {
        let randomNote = GameConstants.Audio.harmonicScale.randomElement() ?? 440.0
        audioService.playNote(frequency: randomNote, duration: GameConstants.Audio.defaultNoteDuration)
    }
    
    private func playBallCollisionSound() {
        let randomNote = GameConstants.Audio.harmonicScale.randomElement() ?? 440.0
        audioService.playBallCollision(frequency: randomNote)
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
            
            // Descobrir qual é a parede (secondBody)
            if let wallNode = secondBody.node {
                // Tentar ler nota configurada
                if let noteIndex = wallNode.userData?["noteIndex"] as? Int,
                   noteIndex < GameConstants.Audio.harmonicScale.count {
                    let freq = GameConstants.Audio.harmonicScale[noteIndex]
                    audioService.playNote(frequency: freq, duration: GameConstants.Audio.defaultNoteDuration)
                } else {
                    playRandomNote()
                }
                
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
}
