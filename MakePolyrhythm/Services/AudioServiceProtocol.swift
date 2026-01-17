import Foundation

/// Protocolo que define o contrato para serviços de áudio.
protocol AudioServiceProtocol {
    /// Toca uma nota com a frequência especificada.
    /// - Parameters:
    ///   - frequency: A frequência em Hz.
    ///   - duration: A duração da nota em segundos.
    func playNote(frequency: Float, duration: Double)
}
