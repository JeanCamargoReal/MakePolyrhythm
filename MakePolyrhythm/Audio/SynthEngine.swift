import AVFoundation

/// Gerencia a síntese de áudio para o Polyrhythm App.
/// Utiliza AVAudioEngine para baixa latência.
final class SynthEngine {
    static let shared = SynthEngine()
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    // Formato padrão para o mixer
    private var format: AVAudioFormat?
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        let mainMixer = engine.mainMixerNode
        let outputNode = engine.outputNode
        let format = outputNode.inputFormat(forBus: 0)
        self.format = format
        
        // Conexões: Player -> Mixer Principal -> Saída
        engine.attach(playerNode)
        engine.connect(playerNode, to: mainMixer, format: format)
        engine.connect(mainMixer, to: outputNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Erro ao iniciar AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    /// Toca uma nota com frequência especificada e duração curta.
    /// - Parameter frequency: Frequência em Hz (ex: 440.0 para Lá)
    func playNote(frequency: Float, duration: Double = 0.1) {
        guard let format = self.format else { return }
        
        let sampleRate = Float(format.sampleRate)
        let totalFrames = UInt32(duration * Double(sampleRate))
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return }
        buffer.frameLength = totalFrames
        
        // Gerar onda senoidal simples
        let channels = Int(format.channelCount)
        if let floatChannelData = buffer.floatChannelData {
            for frame in 0..<Int(totalFrames) {
                let time = Float(frame) / sampleRate
                let value = sin(2.0 * Float.pi * frequency * time)
                
                // Aplicar um fade-out simples para evitar "clique" no final
                let envelope = 1.0 - (Float(frame) / Float(totalFrames))
                
                for channel in 0..<channels {
                    floatChannelData[channel][frame] = value * envelope * 0.5 // 0.5 amplitude
                }
            }
        }
        
        // Agendar e tocar
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts) {
            // Completion handler
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
