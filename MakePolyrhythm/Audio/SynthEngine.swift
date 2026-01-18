import AVFoundation

/// Gerencia a síntese de áudio para o Polyrhythm App.
/// Utiliza AVAudioEngine com efeitos (Reverb, Delay) para um som polifônico e imersivo.
final class SynthEngine: AudioServiceProtocol {
    static let shared = SynthEngine()
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    
    // Nós de Efeito
    private let reverbNode = AVAudioUnitReverb()
    private let delayNode = AVAudioUnitDelay()
    
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
        
        // Configurar Efeitos
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 20 // 40% Reverb
        
        delayNode.delayTime = 0.15 // Eco rítmico
        delayNode.feedback = 20
        delayNode.lowPassCutoff = 7500
        delayNode.wetDryMix = 20
        
        // Conexões: Player -> Delay -> Reverb -> Mixer -> Saída
        engine.attach(playerNode)
        engine.attach(delayNode)
        engine.attach(reverbNode)
        
        engine.connect(playerNode, to: delayNode, format: format)
        engine.connect(delayNode, to: reverbNode, format: format)
        engine.connect(reverbNode, to: mainMixer, format: format)
        engine.connect(mainMixer, to: outputNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Erro ao iniciar AVAudioEngine: \(error.localizedDescription)")
        }
    }
    
    /// Toca uma nota com timbre de sino/harpa (polifônico e harmônico).
    /// - Parameter frequency: Frequência em Hz.
    func playNote(frequency: Float, duration: Double = 0.3) { // Duração base aumentada para o "ring"
        generateAndPlayBellSound(frequency: frequency, duration: duration, isPercussive: false)
    }
    
    /// Toca um som de colisão de bola (mais curto e brilhante).
    func playBallCollision(frequency: Float) {
        generateAndPlayBellSound(frequency: frequency, duration: 0.2, isPercussive: true)
    }
    
    private func generateAndPlayBellSound(frequency: Float, duration: Double, isPercussive: Bool) {
        guard let format = self.format else { return }
        
        let sampleRate = Float(format.sampleRate)
        let totalFrames = UInt32(duration * Double(sampleRate))
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return }
        buffer.frameLength = totalFrames
        
        let channels = Int(format.channelCount)
        if let floatChannelData = buffer.floatChannelData {
            for frame in 0..<Int(totalFrames) {
                let t = Float(frame) / sampleRate
                let progress = Float(frame) / Float(totalFrames)
                
                // Envelope (Ataque rápido, Decay longo e suave)
                let envelope = pow(1.0 - progress, isPercussive ? 4.0 : 2.5)
                
                // Síntese Aditiva (Timbre de Sino/Harpa)
                var value: Float = 0.0
                
                // Fundamental
                value += sin(2.0 * Float.pi * frequency * t) * 1.0
                
                // 2ª Harmônica (Oitava) - Corpo
                value += sin(2.0 * Float.pi * (frequency * 2.0) * t) * 0.5
                
                // 3ª Harmônica (Quinta) - Harmonia
                value += sin(2.0 * Float.pi * (frequency * 3.0) * t) * 0.25
                
                // Inarmônica (Metal/Brilho)
                if isPercussive {
                    // Adiciona um brilho metálico agudo que decai rápido
                    let metalEnvelope = pow(1.0 - progress, 8.0)
                    value += sin(2.0 * Float.pi * (frequency * 4.2) * t) * 0.3 * metalEnvelope
                }
                
                // Normalizar amplitude (evitar distorção) e aplicar volume global
                value *= 0.3 * envelope
                
                for channel in 0..<channels {
                    floatChannelData[channel][frame] = value
                }
            }
        }
        
        scheduleBuffer(buffer)
    }
    
    private func scheduleBuffer(_ buffer: AVAudioPCMBuffer) {
        // .interruptsAtLoop permitiria loop, mas queremos "one shot".
        // O playerNode mistura buffers sobrepostos automaticamente, criando polifonia.
        playerNode.scheduleBuffer(buffer, at: nil, options: []) {
            // Completion handler
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
