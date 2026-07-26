import AppKit
import SwiftUI

struct ThemedBackground: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            if theme == .glass {
                WindowGlassEffect(material: .underWindowBackground)
                LinearGradient(
                    colors: [
                        Color(red: 0.015, green: 0.08, blue: 0.12).opacity(0.34),
                        Color(red: 0.08, green: 0.045, blue: 0.14).opacity(0.26),
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(.cyan.opacity(0.055))
                    .frame(width: 500)
                    .blur(radius: 120)
                    .offset(x: -350, y: -220)
                Circle()
                    .fill(.purple.opacity(0.065))
                    .frame(width: 520)
                    .blur(radius: 140)
                    .offset(x: 420, y: 260)
            } else {
                Color(red: 0.84, green: 0.87, blue: 0.91)
            }
        }
        .ignoresSafeArea()
    }
}

struct SurfaceModifier: ViewModifier {
    let theme: AppTheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if theme == .glass {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.white.opacity(0.038))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(.white.opacity(0.095), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(red: 0.84, green: 0.87, blue: 0.91))
                        .shadow(color: .white.opacity(0.95), radius: 8, x: -6, y: -6)
                        .shadow(color: .black.opacity(0.20), radius: 10, x: 7, y: 7)
                )
        }
    }
}

struct WindowGlassEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .underWindowBackground

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.state = .active
    }
}

struct WindowConfigurator: NSViewRepresentable {
    let theme: AppTheme

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }

    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.toolbarStyle = .unifiedCompact
        window.appearance = NSAppearance(
            named: theme == .glass ? .darkAqua : .aqua
        )
        window.isMovableByWindowBackground = false
        window.hasShadow = true
    }
}

extension View {
    func themedSurface(_ theme: AppTheme, cornerRadius: CGFloat = 20) -> some View {
        modifier(SurfaceModifier(theme: theme, cornerRadius: cornerRadius))
    }
}
