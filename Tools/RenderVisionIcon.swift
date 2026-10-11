#!/usr/bin/env swift
import AppKit

// Reuses the app's tuningForkPath and brand colors from ViewController.m / UIColor+AppColors.m.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let stack = root.appendingPathComponent("A440/Images.xcassets/VisionIcon.solidimagestack")
let info: [String: Any] = ["info": ["author": "xcode", "version": 1]]
for name in ["Front", "Back"] {
    let folder = stack.appendingPathComponent(name + ".solidimagestacklayer")
    let images = folder.appendingPathComponent("Content.imageset")
    try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!.cgContext
    if name == "Back" {
        let colors = [NSColor(red: 47/255, green: 185/255, blue: 158/255, alpha: 1).cgColor,
                      NSColor(red: 15/255, green: 90/255, blue: 73/255, alpha: 1).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 1024), end: CGPoint(x: 1024, y: 0), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        precondition(bitmap.colorAt(x: 0, y: 0)!.alphaComponent == 1)
    } else {
        context.translateBy(x: 0, y: 1024)
        context.scaleBy(x: 10.24, y: -10.24)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(8); context.setLineCap(.round); context.setLineJoin(.round)
        context.move(to: CGPoint(x: 35, y: 20)); context.addLine(to: CGPoint(x: 35, y: 50))
        context.addQuadCurve(to: CGPoint(x: 50, y: 63), control: CGPoint(x: 35, y: 63))
        context.addQuadCurve(to: CGPoint(x: 65, y: 50), control: CGPoint(x: 65, y: 63))
        context.addLine(to: CGPoint(x: 65, y: 20))
        context.move(to: CGPoint(x: 50, y: 63)); context.addLine(to: CGPoint(x: 50, y: 84)); context.strokePath()
        precondition(bitmap.colorAt(x: 0, y: 0)!.alphaComponent == 0)
        precondition(bitmap.colorAt(x: 512, y: 760)!.alphaComponent > 0.95)
    }
    try bitmap.representation(using: .png, properties: [:])!.write(to: images.appendingPathComponent("Layer.png"))
    try JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted, .sortedKeys]).write(to: folder.appendingPathComponent("Contents.json"))
    let content: [String: Any] = ["info": info["info"]!, "images": [["filename": "Layer.png", "idiom": "vision", "scale": "2x"]]]
    try JSONSerialization.data(withJSONObject: content, options: [.prettyPrinted, .sortedKeys]).write(to: images.appendingPathComponent("Contents.json"))
}
let contents: [String: Any] = ["info": info["info"]!, "layers": [["filename": "Front.solidimagestacklayer"], ["filename": "Back.solidimagestacklayer"]]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: stack.appendingPathComponent("Contents.json"))
print("PASS: original tuning-fork layers rendered at 1024px/2x; opaque background and transparent foreground checked")
