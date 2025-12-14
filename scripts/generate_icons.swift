#!/usr/bin/env swift

import AppKit
import Foundation

// 生成应用图标的脚本
class IconGenerator {

    // 图标尺寸配置
    static let sizes: [(size: Int, filename: String)] = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png")
    ]

    // 绘制截图工具图标
    static func drawScreenshotIcon(size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        // 设置背景渐变色（蓝色到紫色）
        let gradient = NSGradient(colors: [
            NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
            NSColor(red: 0.4, green: 0.3, blue: 0.9, alpha: 1.0)
        ])

        let backgroundPath = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: size, height: size),
                                         xRadius: size * 0.22,
                                         yRadius: size * 0.22)
        gradient?.draw(in: backgroundPath, angle: 135)

        // 计算图标内部元素的缩放
        let padding = size * 0.2
        let contentSize = size - (padding * 2)
        let centerX = size / 2
        let centerY = size / 2

        // 绘制选择框（虚线矩形）
        let selectionRect = NSRect(x: padding + contentSize * 0.15,
                                  y: padding + contentSize * 0.15,
                                  width: contentSize * 0.7,
                                  height: contentSize * 0.7)

        let selectionPath = NSBezierPath(roundedRect: selectionRect,
                                        xRadius: size * 0.05,
                                        yRadius: size * 0.05)
        selectionPath.lineWidth = size * 0.06

        // 设置虚线样式
        let dashPattern: [CGFloat] = [size * 0.08, size * 0.06]
        selectionPath.setLineDash(dashPattern, count: 2, phase: 0)

        NSColor.white.withAlphaComponent(0.9).setStroke()
        selectionPath.stroke()

        // 绘制四个角的控制点
        let cornerSize = size * 0.08
        let corners = [
            CGPoint(x: selectionRect.minX, y: selectionRect.minY),
            CGPoint(x: selectionRect.maxX, y: selectionRect.minY),
            CGPoint(x: selectionRect.minX, y: selectionRect.maxY),
            CGPoint(x: selectionRect.maxX, y: selectionRect.maxY)
        ]

        NSColor.white.setFill()
        for corner in corners {
            let cornerRect = NSRect(x: corner.x - cornerSize / 2,
                                   y: corner.y - cornerSize / 2,
                                   width: cornerSize,
                                   height: cornerSize)
            let cornerPath = NSBezierPath(ovalIn: cornerRect)
            cornerPath.fill()
        }

        // 绘制快门/相机图标
        let shutterRadius = size * 0.12
        let shutterCenter = CGPoint(x: centerX + contentSize * 0.25,
                                   y: centerY - contentSize * 0.25)

        // 外圆（快门外圈）
        let outerCircle = NSBezierPath(ovalIn: NSRect(
            x: shutterCenter.x - shutterRadius,
            y: shutterCenter.y - shutterRadius,
            width: shutterRadius * 2,
            height: shutterRadius * 2
        ))
        NSColor.white.setFill()
        outerCircle.fill()

        // 内圆（快门光圈）
        let innerRadius = shutterRadius * 0.6
        let innerCircle = NSBezierPath(ovalIn: NSRect(
            x: shutterCenter.x - innerRadius,
            y: shutterCenter.y - innerRadius,
            width: innerRadius * 2,
            height: innerRadius * 2
        ))
        NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0).setFill()
        innerCircle.fill()

        // 光圈叶片效果（小三角形）
        let bladeCount = 6
        let bladeLength = innerRadius * 0.4
        for i in 0..<bladeCount {
            let angle = (CGFloat(i) * 2 * .pi / CGFloat(bladeCount)) - .pi / 2
            let bladePath = NSBezierPath()
            bladePath.move(to: shutterCenter)

            let point1 = CGPoint(
                x: shutterCenter.x + cos(angle - 0.3) * bladeLength,
                y: shutterCenter.y + sin(angle - 0.3) * bladeLength
            )
            let point2 = CGPoint(
                x: shutterCenter.x + cos(angle + 0.3) * bladeLength,
                y: shutterCenter.y + sin(angle + 0.3) * bladeLength
            )

            bladePath.line(to: point1)
            bladePath.line(to: point2)
            bladePath.close()

            NSColor.white.withAlphaComponent(0.5).setFill()
            bladePath.fill()
        }

        image.unlockFocus()
        return image
    }

    // 保存 PNG 图像
    static func savePNG(image: NSImage, to path: String) -> Bool {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return false
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            try pngData.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            print("Error saving PNG: \(error)")
            return false
        }
    }

    // 生成所有尺寸的图标
    static func generateAllIcons(outputDir: String) {
        // 确保输出目录存在
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: outputDir) {
            try? fileManager.createDirectory(atPath: outputDir,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }

        print("开始生成应用图标...")

        for (size, filename) in sizes {
            print("生成 \(filename) (\(size)x\(size))...")

            let icon = drawScreenshotIcon(size: CGFloat(size))
            let path = "\(outputDir)/\(filename)"

            if savePNG(image: icon, to: path) {
                print("✓ 成功: \(filename)")
            } else {
                print("✗ 失败: \(filename)")
            }
        }

        print("\n图标生成完成！")
    }
}

// 获取脚本所在目录的父目录（项目根目录）
let scriptPath = CommandLine.arguments[0]
let scriptURL = URL(fileURLWithPath: scriptPath)
let scriptsDir = scriptURL.deletingLastPathComponent()
let projectRoot = scriptsDir.deletingLastPathComponent()

// 设置输出目录
let outputDir = projectRoot
    .appendingPathComponent("Sources")
    .appendingPathComponent("SwiftScreenShot")
    .appendingPathComponent("Resources")
    .appendingPathComponent("Assets.xcassets")
    .appendingPathComponent("AppIcon.appiconset")
    .path

print("项目根目录: \(projectRoot.path)")
print("图标输出目录: \(outputDir)")
print()

// 生成图标
IconGenerator.generateAllIcons(outputDir: outputDir)
