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
    
    // MARK: - Gestão de Entidades
    
    func addBall() {
        let ball = SKShapeNode(circleOfRadius: GameConstants.Physics.ballRadius)
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
        
        // Posição Aleatória (respeitando margens seguras)
        // Usamos as constantes definidas para garantir que não nasça em local inacessível
        let minX = frame.minX + GameConstants.UI.horizontalMargin + (width/2)
        let maxX = frame.maxX - GameConstants.UI.horizontalMargin - (width/2)
        let minY = frame.minY + GameConstants.UI.bottomSafeArea + (height/2)
        let maxY = frame.maxY - GameConstants.UI.topSafeArea - (height/2)
        
        // Verificação de segurança caso a tela seja muito pequena
        let safeX = minX < maxX ? CGFloat.random(in: minX...maxX) : frame.midX
        let safeY = minY < maxY ? CGFloat.random(in: minY...maxY) : frame.midY
        
        obstacle.position = CGPoint(x: safeX, y: safeY)
        obstacle.zRotation = CGFloat.random(in: 0...CGFloat.pi)
        
        let body = SKPhysicsBody(rectangleOf: size)
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
    
    /// Detecta o início de um toque para selecionar obstáculos.
    /// - Aplica feedback visual (escala/fade) ao selecionar.
    /// - Para a rotação angular física para facilitar a manipulação.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNodes = nodes(at: location)
        
        // Se tocou em um obstáculo
        if let obstacleNode = touchedNodes.first(where: { $0.name == GameConstants.UI.obstacleName }) {
            // Se já havia um selecionado diferente, restaure o visual dele (opcional, simplificado aqui)
            // Para este protótipo, assumimos que o usuário seleciona um novo.
            
            selectedNode = obstacleNode
            
            // Feedback visual de seleção
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.1) // Escala leve para indicar seleção
            let fade = SKAction.fadeAlpha(to: 0.8, duration: 0.1)
            obstacleNode.run(SKAction.group([scaleUp, fade]))
            
            obstacleNode.physicsBody?.angularVelocity = 0
            
        } else {
            // Tocou no fundo -> Deselecionar
            if let prevNode = selectedNode {
                let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
                let fadeBack = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                prevNode.run(SKAction.group([scaleDown, fadeBack]))
            }
            selectedNode = nil
        }
    }
    
    /// Manipula o arrasto de objetos selecionados.
    /// - Restringe o movimento dentro das margens seguras definidas em `GameConstants.UI` para evitar que objetos saiam da tela.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let node = selectedNode else { return }
        let location = touch.location(in: self)
        
        // Usar margens fixas para permitir que o objeto chegue mais perto das bordas,
        // independentemente do seu tamanho (pode haver um leve corte visual, o que é desejado)
        let hMargin = GameConstants.UI.horizontalMargin
        let vMargin = GameConstants.UI.verticalDragMargin
        
        // Definir limites da tela baseados no CENTRO do objeto
        // As margens aqui evitam que o centro do objeto vá além, permitindo que parte do objeto
        // possa tocar/atravessar um pouco a borda, se for grande.
        let minX = frame.minX + hMargin
        let maxX = frame.maxX - hMargin
        let minY = frame.minY + vMargin
        let maxY = frame.maxY - vMargin
        
        // Restringir posição (Clamp)
        let clampedX = min(max(location.x, minX), maxX)
        let clampedY = min(max(location.y, minY), maxY)
        
        node.position = CGPoint(x: clampedX, y: clampedY)
    }
    
    /// Finaliza a interação de toque.
    /// Nota: A seleção é mantida (não é limpa em `touchesEnded`) para permitir a continuação da edição via gestos (pinça/rotação) sem precisar tocar novamente.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Não removemos a seleção ao soltar, para permitir edição via UI.
        // Apenas paramos o arrasto (que é implícito pelo fim do movimento).
        // Poderíamos restaurar a escala/alpha aqui se quiséssemos apenas efeito de "click",
        // mas como é estado de "seleção", manter visualmente distinto ajuda.
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
        // Colisão Bola (1) x Bola (1)
        else if (firstBody.categoryBitMask & GameConstants.Physics.ballCategory != 0) &&
                (secondBody.categoryBitMask & GameConstants.Physics.ballCategory != 0) {
            
            playRandomNote()
        }
    }
    
    private func playRandomNote() {
        let randomNote = GameConstants.Audio.pentatonicScale.randomElement() ?? 440.0
        audioService.playNote(frequency: randomNote, duration: GameConstants.Audio.defaultNoteDuration)
    }
}