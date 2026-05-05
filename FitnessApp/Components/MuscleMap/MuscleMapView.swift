import Foundation
import SwiftUI

struct MuscleMapView: View {
    let activations: [MuscleGroup: Double]
    var selectedMuscle: MuscleGroup?
    var onMuscleTapped: (MuscleGroup) -> Void = { _ in }

    private var maxActivation: Double {
        max(activations.values.max() ?? 0, 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / CombinedBodyLayout.canvasSize.width,
                proxy.size.height / CombinedBodyLayout.canvasSize.height
            )
            let size = CGSize(
                width: CombinedBodyLayout.canvasSize.width * scale,
                height: CombinedBodyLayout.canvasSize.height * scale
            )

            ZStack {
                combinedBody(scale: scale)
                    .frame(width: size.width, height: size.height)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .accessibilityElement(children: .contain)
        }
        .aspectRatio(CombinedBodyLayout.canvasAspectRatio, contentMode: .fit)
        .frame(maxWidth: .infinity)
    }

    private func combinedBody(scale: CGFloat) -> some View {
        ZStack {
            baseView("front_body_base", layout: CombinedBodyLayout.frontBase, scale: scale)
            baseView("back_body_base", layout: CombinedBodyLayout.backBase, scale: scale)

            ForEach(MuscleMapRegionCatalog.regions) { region in
                regionView(region, scale: scale)
            }
        }
    }

    private func baseView(_ assetName: String, layout: RegionLayout, scale: CGFloat) -> some View {
        SVGRegionShape(assetName: assetName)
            .fill(Color.white.opacity(0.09))
            .frame(width: layout.size.width * scale, height: layout.size.height * scale)
            .position(x: layout.point.x * scale, y: layout.point.y * scale)
            .accessibilityHidden(true)
    }

    private func regionView(_ region: MuscleMapRegion, scale: CGFloat) -> some View {
        let layout = layout(for: region)
        let shape = SVGRegionShape(assetName: region.assetRegionName)

        return Button {
            onMuscleTapped(region.muscleGroup)
        } label: {
            shape
                .fill(fillColor(for: region.muscleGroup))
                .overlay {
                    shape
                        .stroke(selectedMuscle == region.muscleGroup ? .white : Color.white.opacity(0.14), lineWidth: selectedMuscle == region.muscleGroup ? 2 : 1)
                }
                .frame(width: layout.size.width * scale, height: layout.size.height * scale)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .position(x: layout.point.x * scale, y: layout.point.y * scale)
        .accessibilityLabel(region.displayName)
        .accessibilityValue(activationText(for: region.muscleGroup))
        .accessibilityHint("Shows exercises and recent volume")
    }

    private func fillColor(for muscle: MuscleGroup) -> Color {
        guard let activation = activations[muscle], activation > 0 else {
            return Color.white.opacity(0.10)
        }
        let strength = min(max(activation / maxActivation, 0.25), 1)
        return AppTheme.green.opacity(0.35 + (0.55 * strength))
    }

    private func activationText(for muscle: MuscleGroup) -> String {
        guard let value = activations[muscle], value > 0 else { return "Inactive" }
        return "\(Int(value)) kilograms recent volume"
    }

    private func layout(for region: MuscleMapRegion) -> RegionLayout {
        CombinedBodyLayout.regions[region.svgRegionID] ?? RegionLayout(point: CGPoint(x: 325, y: 395), size: CGSize(width: 42, height: 42))
    }
}

typealias BodyDiagramView = MuscleMapView

private struct SVGRegionShape: Shape {
    let assetName: String

    func path(in rect: CGRect) -> Path {
        guard let asset = SVGRegionAssetStore.asset(named: assetName) else {
            return Path(CGRect(origin: .zero, size: rect.size))
        }

        let scaleX = rect.width / max(asset.viewBox.width, 1)
        let scaleY = rect.height / max(asset.viewBox.height, 1)

        var path = Path()
        for element in asset.elements {
            switch element {
            case let .move(point):
                path.move(to: point.scaled(from: asset.viewBox, scaleX: scaleX, scaleY: scaleY))
            case let .line(point):
                path.addLine(to: point.scaled(from: asset.viewBox, scaleX: scaleX, scaleY: scaleY))
            case let .curve(control1, control2, point):
                path.addCurve(
                    to: point.scaled(from: asset.viewBox, scaleX: scaleX, scaleY: scaleY),
                    control1: control1.scaled(from: asset.viewBox, scaleX: scaleX, scaleY: scaleY),
                    control2: control2.scaled(from: asset.viewBox, scaleX: scaleX, scaleY: scaleY)
                )
            case .close:
                path.closeSubpath()
            }
        }
        return path
    }
}

private enum SVGRegionAssetStore {
    nonisolated(unsafe) private static var cache: [String: SVGRegionAsset] = [:]

    static func asset(named name: String) -> SVGRegionAsset? {
        if let cached = cache[name] {
            return cached
        }
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "BodyMapAssets")
                ?? Bundle.main.url(forResource: name, withExtension: "svg"),
            let text = try? String(contentsOf: url, encoding: .utf8),
            let asset = SVGRegionAssetParser.parse(text)
        else {
            return nil
        }
        cache[name] = asset
        return asset
    }
}

private struct SVGRegionAsset {
    let viewBox: CGRect
    let elements: [SVGPathElement]
}

private enum SVGPathElement {
    case move(CGPoint)
    case line(CGPoint)
    case curve(CGPoint, CGPoint, CGPoint)
    case close
}

private enum SVGRegionAssetParser {
    static func parse(_ text: String) -> SVGRegionAsset? {
        guard let viewBox = parseViewBox(text), let pathData = parsePathData(text) else {
            return nil
        }
        return SVGRegionAsset(viewBox: viewBox, elements: parseElements(pathData))
    }

    private static func parseViewBox(_ text: String) -> CGRect? {
        guard let value = firstMatch(in: text, pattern: #"viewBox="([^"]+)""#) else { return nil }
        let numbers = value.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
        guard numbers.count == 4 else { return nil }
        return CGRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
    }

    private static func parsePathData(_ text: String) -> String? {
        firstMatch(in: text, pattern: #"d="([^"]+)""#)
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard
            let match = regex.firstMatch(in: text, range: range),
            let captureRange = Range(match.range(at: 1), in: text)
        else {
            return nil
        }
        return String(text[captureRange])
    }

    private static func parseElements(_ pathData: String) -> [SVGPathElement] {
        let tokens = SVGPathTokenizer.tokenize(pathData)
        var parser = SVGPathTokenParser(tokens: tokens)
        return parser.parse()
    }
}

private enum SVGPathToken: Equatable {
    case command(Character)
    case number(CGFloat)
}

private enum SVGPathTokenizer {
    static func tokenize(_ text: String) -> [SVGPathToken] {
        var tokens: [SVGPathToken] = []
        var number = ""

        func flushNumber() {
            guard !number.isEmpty, let value = Double(number) else {
                number = ""
                return
            }
            tokens.append(.number(CGFloat(value)))
            number = ""
        }

        for character in text {
            if character.isLetter {
                flushNumber()
                tokens.append(.command(character))
            } else if character == "-" || character == "+" {
                if !number.isEmpty, !number.hasSuffix("e"), !number.hasSuffix("E") {
                    flushNumber()
                }
                number.append(character)
            } else if character.isNumber || character == "." || character == "e" || character == "E" {
                number.append(character)
            } else {
                flushNumber()
            }
        }
        flushNumber()
        return tokens
    }
}

private struct SVGPathTokenParser {
    var tokens: [SVGPathToken]
    var index = 0
    var current = CGPoint.zero
    var subpathStart = CGPoint.zero
    var command: Character?

    mutating func parse() -> [SVGPathElement] {
        var elements: [SVGPathElement] = []

        while index < tokens.count {
            if case let .command(value) = tokens[index] {
                command = value
                index += 1
            }
            guard let command else { break }

            switch command {
            case "M", "m":
                parseMove(relative: command == "m", elements: &elements)
            case "L", "l":
                parseLines(relative: command == "l", elements: &elements)
            case "H", "h":
                parseHorizontal(relative: command == "h", elements: &elements)
            case "V", "v":
                parseVertical(relative: command == "v", elements: &elements)
            case "C", "c":
                parseCurves(relative: command == "c", elements: &elements)
            case "Z", "z":
                current = subpathStart
                elements.append(.close)
                self.command = nil
            default:
                index += 1
            }
        }

        return elements
    }

    private mutating func parseMove(relative: Bool, elements: inout [SVGPathElement]) {
        guard let point = nextPoint(relative: relative) else { return }
        current = point
        subpathStart = point
        elements.append(.move(point))
        command = relative ? "l" : "L"
        parseLines(relative: relative, elements: &elements)
    }

    private mutating func parseLines(relative: Bool, elements: inout [SVGPathElement]) {
        while let point = nextPoint(relative: relative) {
            current = point
            elements.append(.line(point))
        }
    }

    private mutating func parseHorizontal(relative: Bool, elements: inout [SVGPathElement]) {
        while let x = nextNumber() {
            current = CGPoint(x: relative ? current.x + x : x, y: current.y)
            elements.append(.line(current))
        }
    }

    private mutating func parseVertical(relative: Bool, elements: inout [SVGPathElement]) {
        while let y = nextNumber() {
            current = CGPoint(x: current.x, y: relative ? current.y + y : y)
            elements.append(.line(current))
        }
    }

    private mutating func parseCurves(relative: Bool, elements: inout [SVGPathElement]) {
        while let x1 = nextNumber(), let y1 = nextNumber(), let x2 = nextNumber(), let y2 = nextNumber(), let x = nextNumber(), let y = nextNumber() {
            let control1 = point(x1, y1, relative: relative)
            let control2 = point(x2, y2, relative: relative)
            let end = point(x, y, relative: relative)
            current = end
            elements.append(.curve(control1, control2, end))
        }
    }

    private mutating func nextPoint(relative: Bool) -> CGPoint? {
        guard let x = nextNumber(), let y = nextNumber() else { return nil }
        return point(x, y, relative: relative)
    }

    private func point(_ x: CGFloat, _ y: CGFloat, relative: Bool) -> CGPoint {
        CGPoint(x: relative ? current.x + x : x, y: relative ? current.y + y : y)
    }

    private mutating func nextNumber() -> CGFloat? {
        guard index < tokens.count, case let .number(value) = tokens[index] else {
            return nil
        }
        index += 1
        return value
    }
}

private extension CGPoint {
    func scaled(from viewBox: CGRect, scaleX: CGFloat, scaleY: CGFloat) -> CGPoint {
        CGPoint(x: (x - viewBox.minX) * scaleX, y: (y - viewBox.minY) * scaleY)
    }
}

private struct RegionLayout {
    let point: CGPoint
    let size: CGSize
}

private enum CombinedBodyLayout {
    // Coordinates use the 649x790 body_front_back.svg reference canvas.
    static let canvasSize = CGSize(width: 649, height: 790)
    static let canvasAspectRatio = canvasSize.width / canvasSize.height
    static let frontBase = l(147, 395, 294, 790)
    static let backBase = l(506, 400.5, 286, 779)

    static let regions: [String: RegionLayout] = [
        "back_achilles_left": l(433.13, 684.07, 26.00, 85.00),
        "back_achilles_right": l(578.65, 683.37, 26.00, 84.00),
        "back_calf_inner_left": l(451.44, 601.53, 24.00, 95.00),
        "back_calf_inner_right": l(560.52, 601.19, 25.00, 95.00),
        "back_calf_outer_left": l(425.47, 600.15, 31.00, 94.00),
        "back_calf_outer_right": l(586.61, 600.01, 30.00, 94.00),
        "back_forearm_inner_left": l(396.35, 326.63, 31.00, 85.00),
        "back_forearm_inner_left-1": l(617.77, 326.48, 30.00, 86.00),
        "back_forearm_outer_left": l(380.50, 324.69, 17.00, 86.00),
        "back_forearm_outer_right": l(633.00, 323.00, 16.00, 86.00),
        "back_glutes_left": l(470.76, 389.76, 69.00, 80.00),
        "back_glutes_right": l(542.34, 389.77, 67.00, 80.00),
        "back_hamstring_inner_left": l(467.27, 499.00, 34.00, 133.00),
        "back_hamstring_inner_right": l(545.01, 498.96, 35.00, 133.00),
        "back_hamstring_left": l(442.02, 498.19, 29.00, 121.00),
        "back_hamstring_outer_left": l(426.14, 471.47, 11.00, 94.00),
        "back_hamstring_outer_right": l(586.51, 473.69, 11.00, 97.00),
        "back_hamstring_right": l(570.88, 498.46, 29.00, 122.00),
        "back_lats": l(507.50, 286.00, 147.00, 156.00),
        "back_rhomboids_left": l(452.23, 183.96, 46.00, 48.00),
        "back_rhomboids_left-1": l(563.63, 183.82, 45.00, 48.00),
        "back_shoulder_right": l(591.68, 172.50, 62.00, 55.00),
        "back_shoulder_right-1": l(423.57, 172.58, 62.00, 55.00),
        "back_trap_left": l(479.18, 116.00, 55.00, 56.00),
        "back_trap_right": l(535.00, 115.50, 56.00, 56.00),
        "back_triceps_left": l(407.46, 229.67, 41.00, 77.00),
        "back_triceps_left-1": l(406.59, 259.50, 43.00, 64.00),
        "back_triceps_right": l(608.14, 229.59, 41.00, 77.00),
        "back_triceps_right-1": l(608.77, 258.31, 43.00, 65.00),
        "back_upper_back_left": l(478.00, 194.50, 56.00, 213.00),
        "back_upper_back_right": l(537.50, 194.50, 57.00, 215.00),
        "front_abs_row1_left": l(129.91, 230.88, 32.00, 31.00),
        "front_abs_row1_right": l(166.73, 230.77, 32.00, 31.00),
        "front_abs_row2_left": l(130.51, 263.80, 32.00, 28.00),
        "front_abs_row2_right": l(166.28, 264.20, 31.00, 29.00),
        "front_abs_row3_left": l(130.72, 296.18, 32.00, 29.00),
        "front_abs_row3_right": l(166.08, 296.57, 31.00, 30.00),
        "front_abs_row4_left": l(131.69, 345.11, 30.00, 61.00),
        "front_abs_row4_right": l(165.48, 344.62, 29.00, 60.00),
        "front_adductor_left": l(118.03, 423.25, 40.00, 148.00),
        "front_adductor_right": l(178.60, 422.32, 40.00, 146.00),
        "front_biceps_left": l(44.50, 233.00, 39.00, 78.00),
        "front_biceps_right": l(252.50, 236.50, 39.00, 77.00),
        "front_calf_inner_left": l(92.50, 647.00, 31.00, 148.00),
        "front_calf_inner_right": l(202.50, 650.50, 31.00, 149.00),
        "front_calf_outer_left": l(66.50, 643.50, 23.00, 153.00),
        "front_calf_outer_right": l(228.50, 648.00, 23.00, 154.00),
        "front_chest_left": l(108.00, 177.00, 80.00, 70.00),
        "front_chest_right": l(190.00, 177.00, 80.00, 70.00),
        "front_forearm_inner_left": l(36.00, 317.00, 32.00, 84.00),
        "front_forearm_inner_right": l(260.50, 317.00, 31.00, 84.00),
        "front_forearm_outer_left": l(20.50, 307.00, 21.00, 102.00),
        "front_forearm_outer_right": l(276.00, 308.00, 20.00, 102.00),
        "front_hip_flexor_left": l(80.92, 362.70, 21.00, 55.00),
        "front_hip_flexor_right": l(216.50, 370.50, 21.00, 55.00),
        "front_knee_left": l(91.50, 556.00, 35.00, 66.00),
        "front_knee_right": l(206.50, 562.00, 35.00, 66.00),
        "front_oblique_left": l(100.23, 308.46, 27.00, 71.00),
        "front_oblique_right": l(196.94, 308.49, 27.00, 70.00),
        "front_quad_left": l(110.00, 485.50, 24.00, 99.00),
        "front_quad_left-1": l(87.00, 439.50, 48.00, 155.00),
        "front_quad_right": l(185.50, 490.50, 25.00, 99.00),
        "front_quad_right-1": l(207.00, 441.50, 48.00, 155.00),
        "front_serratus_left1": l(95.07, 226.00, 31.00, 28.00),
        "front_serratus_left2": l(95.71, 244.41, 29.00, 30.00),
        "front_serratus_left3": l(98.36, 266.32, 24.00, 30.00),
        "front_serratus_right1": l(202.35, 225.84, 31.00, 27.00),
        "front_serratus_right2": l(200.69, 245.11, 29.00, 31.00),
        "front_serratus_right3": l(198.08, 266.56, 24.00, 30.00),
        "front_shoulder_left": l(57.00, 166.50, 54.00, 65.00),
        "front_shoulder_right": l(238.50, 166.50, 53.00, 65.00),
        "front_upper_chest_left": l(102.00, 149.00, 58.00, 30.00),
        "front_upper_chest_right": l(194.50, 149.00, 57.00, 30.00)
    ]

    private static func l(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> RegionLayout {
        RegionLayout(point: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
}
