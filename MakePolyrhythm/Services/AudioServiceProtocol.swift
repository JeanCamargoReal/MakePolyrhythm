import Foundation

/// Protocolo que define a interface para o serviço de síntese e reprodução de áudio.
///
/// Permite o desacoplamento entre a lógica do jogo (`PolyrhythmScene`) e a implementação concreta do motor de áudio (`SynthEngine`).
/// Isso facilita testes (mocks) e futuras substituições de tecnologia de áudio.
protocol AudioServiceProtocol {
    
    /// Toca uma nota musical sintetizada com timbre harmônico (ex: Sino/Harpa).
    ///
    /// - Parameters:
    ///   - frequency: A frequência fundamental da nota em Hertz (Hz).
    ///   - duration: A duração desejada do som em segundos. O envelope do som pode estender-se além disso (release).
    func playNote(frequency: Float, duration: Double)
    
    /// Toca um som de impacto específico para colisões entre bolas.
    ///
    /// Geralmente possui um timbre mais percussivo, curto e brilhante que as notas padrão.
    /// - Parameter frequency: A frequência base para o som de impacto.
    func playBallCollision(frequency: Float)
}
