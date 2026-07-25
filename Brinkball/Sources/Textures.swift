import SpriteKit
import UIKit

/// Programmatic Core Graphics textures — crisp at any scale, no alpha-extraction risk.
enum Textures {
    /// A luminous glass orb: radial gradient body, specular highlight, soft rim.
    static func orb(diameter: CGFloat, color: UIColor, scale: CGFloat = 3) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size, format: format(scale: scale))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)
            var hue: CGFloat = 0, sat: CGFloat = 0, bri: CGFloat = 0, alp: CGFloat = 0
            color.getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alp)
            let bright = UIColor(hue: hue, saturation: sat * 0.55, brightness: 1.0, alpha: 1)
            let mid = color
            let dark = UIColor(hue: hue, saturation: min(sat * 1.15, 1), brightness: bri * 0.42, alpha: 1)

            // Body
            let colors = [bright.cgColor, mid.cgColor, dark.cgColor] as CFArray
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1])!
            cg.saveGState()
            cg.addEllipse(in: rect.insetBy(dx: 0.5, dy: 0.5))
            cg.clip()
            cg.drawRadialGradient(grad,
                                  startCenter: CGPoint(x: size.width * 0.38, y: size.height * 0.34), startRadius: 0,
                                  endCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5), endRadius: diameter * 0.62,
                                  options: .drawsAfterEndLocation)
            cg.restoreGState()

            // Specular highlight
            let hl = CGRect(x: size.width * 0.22, y: size.height * 0.14, width: diameter * 0.30, height: diameter * 0.20)
            let hlGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: [UIColor.white.withAlphaComponent(0.95).cgColor,
                                             UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
                                    locations: [0, 1])!
            cg.saveGState()
            cg.addEllipse(in: hl)
            cg.clip()
            cg.drawRadialGradient(hlGrad,
                                  startCenter: CGPoint(x: hl.midX, y: hl.midY), startRadius: 0,
                                  endCenter: CGPoint(x: hl.midX, y: hl.midY), endRadius: hl.width * 0.7,
                                  options: .drawsAfterEndLocation)
            cg.restoreGState()

            // Rim light
            cg.setStrokeColor(bright.withAlphaComponent(0.65).cgColor)
            cg.setLineWidth(1.2)
            cg.strokeEllipse(in: rect.insetBy(dx: 1, dy: 1))
        }
        return SKTexture(image: image)
    }

    /// The ember ball: hot white-yellow core into deep orange.
    static func ember(diameter: CGFloat, scale: CGFloat = 3) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size, format: format(scale: scale))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)
            let colors = [UIColor(red: 1, green: 0.98, blue: 0.88, alpha: 1).cgColor,
                          UIColor(red: 1, green: 0.72, blue: 0.20, alpha: 1).cgColor,
                          UIColor(red: 0.92, green: 0.32, blue: 0.06, alpha: 1).cgColor] as CFArray
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.5, 1])!
            cg.addEllipse(in: rect.insetBy(dx: 0.5, dy: 0.5))
            cg.clip()
            cg.drawRadialGradient(grad,
                                  startCenter: CGPoint(x: size.width * 0.42, y: size.height * 0.40), startRadius: 0,
                                  endCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5), endRadius: diameter * 0.60,
                                  options: .drawsAfterEndLocation)
        }
        return SKTexture(image: image)
    }

    /// Soft round glow for particles and halos.
    static func glowDot(diameter: CGFloat = 32, color: UIColor = .white, scale: CGFloat = 2) -> SKTexture {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size, format: format(scale: scale))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [color.withAlphaComponent(0.9).cgColor,
                                           color.withAlphaComponent(0).cgColor] as CFArray,
                                  locations: [0, 1])!
            cg.drawRadialGradient(grad,
                                  startCenter: CGPoint(x: size.width / 2, y: size.height / 2), startRadius: 0,
                                  endCenter: CGPoint(x: size.width / 2, y: size.height / 2), endRadius: diameter / 2,
                                  options: .drawsAfterEndLocation)
        }
        return SKTexture(image: image)
    }

    /// Bottom-edge danger glow: red gradient fading upward from the drain.
    static func bottomGlow(width: CGFloat, height: CGFloat, scale: CGFloat = 2) -> SKTexture {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size, format: format(scale: scale))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                  colors: [UIColor(red: 1, green: 0.12, blue: 0.16, alpha: 0.85).cgColor,
                                           UIColor(red: 1, green: 0.12, blue: 0.16, alpha: 0).cgColor] as CFArray,
                                  locations: [0, 1])!
            cg.drawLinearGradient(grad,
                                  start: CGPoint(x: 0, y: size.height),
                                  end: CGPoint(x: 0, y: 0),
                                  options: [])
        }
        return SKTexture(image: image)
    }

    private static func format(scale: CGFloat) -> UIGraphicsImageRendererFormat {
        let f = UIGraphicsImageRendererFormat()
        f.scale = scale
        f.opaque = false
        return f
    }
}
