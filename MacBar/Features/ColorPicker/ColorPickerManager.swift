import AppKit
import SwiftUI

@Observable
final class ColorPickerManager {
    var pickedColor: NSColor?
    var hexString = ""
    var rgbString = ""
    var hslString = ""
    var swiftUIString = ""

    @MainActor
    func pickColor() async {
        let sampler = NSColorSampler()
        guard let color = await sampler.sample() else {
            return
        }

        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        pickedColor = rgb

        let r = rgb.redComponent
        let g = rgb.greenComponent
        let b = rgb.blueComponent

        let ri = Int(r * 255)
        let gi = Int(g * 255)
        let bi = Int(b * 255)

        hexString = String(format: "#%02X%02X%02X", ri, gi, bi)
        rgbString = "rgb(\(ri), \(gi), \(bi))"
        hslString = computeHSL(r: r, g: g, b: b)
        swiftUIString = String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", r, g, b)
    }

    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func computeHSL(r: Double, g: Double, b: Double) -> String {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        let l = (maxC + minC) / 2

        if delta == 0 {
            return "hsl(0, 0%, \(Int(l * 100))%)"
        }

        let s = l < 0.5 ? delta / (maxC + minC) : delta / (2 - maxC - minC)

        var h: Double
        if maxC == r {
            h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxC == g {
            h = (b - r) / delta + 2
        } else {
            h = (r - g) / delta + 4
        }

        h = h * 60
        if h < 0 {
            h += 360
        }

        return "hsl(\(Int(h)), \(Int(s * 100))%, \(Int(l * 100))%)"
    }
}
