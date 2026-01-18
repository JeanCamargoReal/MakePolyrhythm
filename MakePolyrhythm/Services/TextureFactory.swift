import SpriteKit
import UIKit

/// Factory responsável por gerar texturas procedurais para o jogo.
/// Segue o princípio de Responsabilidade Única (SRP), separando a lógica de renderização da lógica de física.
struct TextureFactory {
    
    /// Cria uma textura circular básica (branca).
    static func createCircle(radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        return renderImage(size: size) { ctx in
            ctx.setFillColor(UIColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// Gera uma textura de gradiente radial vibrante para bolas (Estilo 2D Moderno).
    static func createRadialGradient(color: UIColor, radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        return renderImage(size: size) { ctx in
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
    }
    
    /// Gera uma textura de gradiente linear para obstáculos.
    static func createLinearGradient(path: CGPath, color: UIColor, size: CGSize) -> SKTexture {
        return renderImage(size: size) { ctx in
            let pathBounds = path.boundingBox
            
            // Centralizar path no contexto
            ctx.translateBy(x: -pathBounds.minX, y: -pathBounds.minY)
            
            // Clipar pelo path
            ctx.addPath(path)
            ctx.clip()
            
            // Gradiente Linear Diagonal: Topo-Esq (Claro) -> Base-Dir (Escuro)
            let colors = [UIColor.white.withAlphaComponent(0.4).cgColor, color.cgColor] as CFArray
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                let start = CGPoint(x: pathBounds.minX, y: pathBounds.minY)
                let end = CGPoint(x: pathBounds.maxX, y: pathBounds.maxY)
                ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
            }
        }
    }
    
    /// Gera uma textura de gradiente vertical para triângulos.
    static func createVerticalGradient(path: CGPath, color: UIColor, size: CGSize) -> SKTexture {
        return renderImage(size: size) { ctx in
            let pathBounds = path.boundingBox
            
            ctx.translateBy(x: -pathBounds.minX, y: -pathBounds.minY)
            
            ctx.addPath(path)
            ctx.clip()
            
            // Gradiente Linear Vertical
            let colors = [UIColor.white.withAlphaComponent(0.6).cgColor, color.cgColor] as CFArray
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0.0, 1.0]) {
                let start = CGPoint(x: pathBounds.midX, y: 0)
                let end = CGPoint(x: pathBounds.midX, y: size.height)
                ctx.drawLinearGradient(gradient, start: start, end: end, options: [])
            }
        }
    }
    
    /// Gera uma textura de gradiente radial para polígonos (Diamond).
    static func createRadialGradientForPolygon(path: CGPath, color: UIColor, size: CGSize) -> SKTexture {
        return renderImage(size: size) { ctx in
            let pathBounds = path.boundingBox
            let center = CGPoint(x: pathBounds.midX, y: pathBounds.midY)
            let maxRadius = max(pathBounds.width, pathBounds.height) / 2
            
            ctx.translateBy(x: -pathBounds.minX, y: -pathBounds.minY)
            
            ctx.addPath(path)
            ctx.clip()
            
            let colors = [UIColor.white.withAlphaComponent(0.6).cgColor, color.cgColor] as CFArray
            let locations: [CGFloat] = [0.0, 1.0]
            
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: maxRadius, options: [])
            }
        }
    }
    
    // MARK: - Helper Privado
    
    private static func renderImage(size: CGSize, drawing: (CGContext) -> Void) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            drawing(context.cgContext)
        }
        return SKTexture(image: image)
    }
}
