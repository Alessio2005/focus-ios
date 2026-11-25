import SwiftUI

/// Kaart in de stijl van de Android-app.
struct Card<Content: View>: View {
    var title: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title).font(.headline)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct StatTile: View {
    let value: String
    let label: String
    var systemImage: String?

    var body: some View {
        VStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage).font(.title3).foregroundStyle(.tint)
            }
            Text(value).font(.title2.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Scrollend scherm met grijze achtergrond en kaarten.
struct ScrollScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) { content }
                .padding(16)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// De plant groeit mee met je level (fase 0 t/m 4).
struct PlantView: View {
    let stage: Int

    private let leaf = Color(red: 0x16 / 255, green: 0xA3 / 255, blue: 0x4A / 255)
    private let leafDark = Color(red: 0x15 / 255, green: 0x80 / 255, blue: 0x3D / 255)
    private let stem = Color(red: 0x4D / 255, green: 0x7C / 255, blue: 0x0F / 255)
    private let pot = Color(red: 0xB4 / 255, green: 0x53 / 255, blue: 0x09 / 255)
    private let soil = Color(red: 0x78 / 255, green: 0x35 / 255, blue: 0x0F / 255)

    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            let potTop = h * 0.70

            // Pot
            var potPath = Path()
            potPath.move(to: CGPoint(x: w * 0.28, y: potTop))
            potPath.addLine(to: CGPoint(x: w * 0.72, y: potTop))
            potPath.addLine(to: CGPoint(x: w * 0.65, y: h * 0.98))
            potPath.addLine(to: CGPoint(x: w * 0.35, y: h * 0.98))
            potPath.closeSubpath()
            context.fill(potPath, with: .color(pot))
            context.fill(Path(roundedRect: CGRect(x: w * 0.25, y: potTop - h * 0.05, width: w * 0.5, height: h * 0.08),
                              cornerRadius: 4), with: .color(pot))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.3, y: potTop - h * 0.05, width: w * 0.4, height: h * 0.05)),
                         with: .color(soil))

            if stage == 0 {
                // Zaadje
                context.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: potTop - h * 0.09, width: w * 0.08, height: h * 0.05)),
                             with: .color(Color(red: 0x92 / 255, green: 0x40 / 255, blue: 0x0E / 255)))
                return
            }

            let heights: [CGFloat] = [0, 0.14, 0.26, 0.38, 0.48]
            let stemTop = potTop - h * heights[min(stage, 4)]
            var stemPath = Path()
            stemPath.move(to: CGPoint(x: w / 2, y: potTop - h * 0.03))
            stemPath.addLine(to: CGPoint(x: w / 2, y: stemTop))
            context.stroke(stemPath, with: .color(stem), style: StrokeStyle(lineWidth: w * 0.035, lineCap: .round))

            func leafAt(_ y: CGFloat, left: Bool, scale: CGFloat) {
                let lw = w * 0.22 * scale, lh = h * 0.08 * scale
                let rect = CGRect(x: left ? w / 2 - lw : w / 2, y: y - lh / 2, width: lw, height: lh)
                context.fill(Path(ellipseIn: rect), with: .color(left ? leaf : leafDark))
            }

            let leafCount = min(stage * 2, 7)
            for i in 0..<leafCount {
                let t = CGFloat(i + 1) / CGFloat(leafCount + 1)
                let y = potTop - (potTop - stemTop) * t
                leafAt(y, left: i % 2 == 0, scale: 0.7 + 0.3 * (1 - t))
            }

            if stage >= 4 {
                // Bloem
                for k in 0..<6 {
                    let angle = Double(k) / 6 * 2 * .pi
                    let cx = w / 2 + CGFloat(cos(angle)) * w * 0.07
                    let cy = stemTop + CGFloat(sin(angle)) * w * 0.07
                    context.fill(Path(ellipseIn: CGRect(x: cx - w * 0.055, y: cy - w * 0.055, width: w * 0.11, height: w * 0.11)),
                                 with: .color(Color(red: 0xF5 / 255, green: 0x9E / 255, blue: 0x0B / 255)))
                }
                context.fill(Path(ellipseIn: CGRect(x: w / 2 - w * 0.05, y: stemTop - w * 0.05, width: w * 0.1, height: w * 0.1)),
                             with: .color(Color(red: 0xFD / 255, green: 0xE6 / 255, blue: 0x8A / 255)))
            } else {
                // Knop bovenaan
                context.fill(Path(ellipseIn: CGRect(x: w / 2 - w * 0.04, y: stemTop - w * 0.06, width: w * 0.08, height: w * 0.1)),
                             with: .color(leaf))
            }
        }
        .accessibilityLabel("Plant, groeifase \(stage + 1) van 5")
    }
}

/// Ring die laat zien hoeveel van de huidige fase voorbij is.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(Color.accentColor.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
        }
    }
}

func formatClock(_ seconds: TimeInterval) -> String {
    let s = max(Int(seconds.rounded(.up)), 0)
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%02d:%02d", m, sec)
}

func formatMinutes(_ minutes: Int) -> String {
    minutes >= 60 ? "\(minutes / 60) u \(minutes % 60) m" : "\(minutes) min"
}
