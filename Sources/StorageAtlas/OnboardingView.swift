import SwiftUI

private enum OnboardingStep: Int, CaseIterable {
    case reveal
    case controls
    case folder
}

struct OnboardingView: View {
    @EnvironmentObject private var model: StorageModel
    let onFinish: () -> Void

    @State private var step: OnboardingStep = .reveal
    @State private var demoSelection: StorageNode?
    @State private var entrance = false

    private let demoRoot = StorageNode.onboardingDemo

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                topBar
                stepContent
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .modifier(
                            active: OnboardingTransition(progress: 1, direction: 1),
                            identity: OnboardingTransition(progress: 0, direction: 1)
                        ),
                        removal: .modifier(
                            active: OnboardingTransition(progress: 1, direction: -1),
                            identity: OnboardingTransition(progress: 0, direction: -1)
                        )
                    ))
                footer
            }
            .padding(28)
        }
        .preferredColorScheme(.dark)
        .foregroundStyle(.white)
        .onAppear {
            demoSelection = demoRoot
            withAnimation(.easeOut(duration: 0.7)) { entrance = true }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: step)
    }

    private var onboardingBackground: some View {
        ZStack {
            WindowGlassEffect(material: .hudWindow)
            Color.black.opacity(0.62)
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.16, blue: 0.20).opacity(0.24),
                    .clear,
                    Color(red: 0.12, green: 0.055, blue: 0.20).opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [.white.opacity(0.045), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "square.3.layers.3d.top.filled")
                    .foregroundStyle(.cyan)
                Text("STORAGE ATLAS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.8)
            }
            Spacer()
            Text("0\(step.rawValue + 1)  /  0\(OnboardingStep.allCases.count)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.38))
            Button("Skip") { onFinish() }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
                .padding(.leading, 20)
        }
        .frame(height: 36)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .reveal:
            revealStep
        case .controls:
            controlsStep
        case .folder:
            folderStep
        }
    }

    private var revealStep: some View {
        HStack(spacing: 30) {
            VStack(alignment: .leading, spacing: 0) {
                Text("YOUR STORAGE,\nFROM ABOVE.")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .tracking(-1.8)
                    .lineSpacing(-3)
                    .opacity(entrance ? 1 : 0)
                    .offset(y: entrance ? 0 : 22)

                Text("Every block is something real on your Mac.\nBig footprint, big appetite.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineSpacing(4)
                    .padding(.top, 22)
                    .opacity(entrance ? 1 : 0)
                    .offset(y: entrance ? 0 : 16)

                HStack(spacing: 22) {
                    stat("12.4 GB", "DEVELOPER")
                    stat("8.8 GB", "MEDIA")
                    stat("4.1 GB", "DOCUMENTS")
                }
                .padding(.top, 34)

                Button {
                    advance()
                } label: {
                    HStack(spacing: 10) {
                        Text("Show me how")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryOnboardingButton())
                .keyboardShortcut(.defaultAction)
                .padding(.top, 38)
            }
            .frame(maxWidth: 410, alignment: .leading)

            liveMapCard(interactive: false)
                .overlay(alignment: .topTrailing) {
                    Text("LIVE PREVIEW")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(.cyan.opacity(0.75))
                        .padding(18)
                }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
    }

    private var controlsStep: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Learn it in ten seconds.")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("This is the real map. Try it now.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                if let demoSelection, demoSelection.id != demoRoot.id {
                    Label(demoSelection.name, systemImage: "scope")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.cyan.opacity(0.1), in: Capsule())
                        .overlay(Capsule().stroke(.cyan.opacity(0.25)))
                }
            }

            liveMapCard(interactive: true)
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 8) {
                        controlPill("cursorarrow.click.2", "Click", "focus")
                        controlPill("rotate.3d.fill", "Drag", "rotate")
                        controlPill("computermouse.fill", "Scroll", "zoom")
                        controlPill("finder", "Double-click", "Finder")
                    }
                    .padding(16)
                }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
    }

    private var folderStep: some View {
        HStack(spacing: 48) {
            VStack(alignment: .leading, spacing: 22) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.cyan.opacity(0.09))
                        .frame(width: 104, height: 104)
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.cyan.opacity(0.2)))
                    Image(systemName: model.root == nil ? "folder.fill.badge.plus" : "checkmark")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(model.root == nil ? .cyan : .green)
                        .contentTransition(.symbolEffect(.replace))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(model.root == nil ? "Pick where to begin." : "Ready for takeoff.")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text(model.root == nil
                         ? "Start with your home folder, Downloads, or any drive. You can map another location whenever you want."
                         : "\(model.root?.name ?? "Your folder") is mapped and ready to explore.")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineSpacing(4)
                        .frame(maxWidth: 420, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    privacyLine("lock.shield.fill", "Scanned entirely on your Mac")
                    privacyLine("eye.slash.fill", "Hidden files and app packages are skipped")
                    privacyLine("icloud.slash.fill", "No uploads. No account. No analytics.")
                }
            }

            VStack(spacing: 18) {
                if model.isScanning {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.cyan)
                    Text(model.scanProgress)
                        .font(.system(size: 14, weight: .medium))
                    Text("Large folders can take a moment.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.38))
                } else if let root = model.root {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text(root.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("\(root.formattedSize) · \(root.fileCount.formatted()) files")
                        .foregroundStyle(.white.opacity(0.48))
                    Button("Open the atlas") { onFinish() }
                        .buttonStyle(PrimaryOnboardingButton())
                        .keyboardShortcut(.defaultAction)
                    Button("Choose a different folder") { model.chooseAndScan() }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.45))
                } else {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.72))
                    Text("Choose a folder")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("macOS will ask you to confirm access.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.42))
                    Button("Choose Folder…") { model.chooseAndScan() }
                        .buttonStyle(PrimaryOnboardingButton())
                        .keyboardShortcut(.defaultAction)
                }
            }
            .frame(width: 300, height: 310)
            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.09)))
            .shadow(color: .black.opacity(0.32), radius: 30, y: 18)
        }
        .padding(.horizontal, 54)
    }

    private func liveMapCard(interactive: Bool) -> some View {
        StorageSceneView(
            root: demoRoot,
            selected: $demoSelection,
            theme: .glass,
            onReveal: { _ in }
        )
        .allowsHitTesting(interactive)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.1)))
        .shadow(color: .cyan.opacity(0.08), radius: 40)
    }

    private var footer: some View {
        HStack {
            if step != .reveal {
                Button {
                    back()
                } label: {
                    Label("Back", systemImage: "arrow.left")
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            } else {
                Color.clear.frame(width: 50, height: 1)
            }

            Spacer()
            HStack(spacing: 7) {
                ForEach(OnboardingStep.allCases, id: \.rawValue) { item in
                    Capsule()
                        .fill(item == step ? .white : .white.opacity(0.18))
                        .frame(width: item == step ? 25 : 7, height: 7)
                }
            }
            Spacer()

            if step == .controls {
                Button {
                    advance()
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
            } else {
                Color.clear.frame(width: 82, height: 1)
            }
        }
        .frame(height: 36)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.32))
        }
    }

    private func controlPill(_ symbol: String, _ action: String, _ result: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .foregroundStyle(.cyan)
            Text(action).fontWeight(.semibold)
            Text(result).foregroundStyle(.white.opacity(0.42))
        }
        .font(.system(size: 11))
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(.black.opacity(0.42), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.09)))
    }

    private func privacyLine(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.48))
    }

    private func advance() {
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    private func back() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previous
    }
}

private struct OnboardingTransition: ViewModifier {
    let progress: CGFloat
    let direction: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(1 - progress)
            .blur(radius: progress * 10)
            .scaleEffect(1 - progress * 0.025)
            .offset(x: direction * progress * 80)
    }
}

private struct PrimaryOnboardingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(.white, in: Capsule())
            .shadow(color: .white.opacity(configuration.isPressed ? 0.12 : 0.22),
                    radius: configuration.isPressed ? 6 : 16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

private extension StorageNode {
    static var onboardingDemo: StorageNode {
        let base = URL(fileURLWithPath: "/StorageAtlasPreview")

        func file(_ name: String, _ gb: Double, _ ext: String) -> StorageNode {
            let url = base.appendingPathComponent(name).appendingPathExtension(ext)
            return StorageNode(
                id: url,
                url: url,
                name: "\(name).\(ext)",
                byteSize: Int64(gb * 1_000_000_000),
                isDirectory: false,
                children: [],
                fileCount: 1
            )
        }

        func folder(_ name: String, _ gb: Double, children: [StorageNode]) -> StorageNode {
            let url = base.appendingPathComponent(name)
            return StorageNode(
                id: url,
                url: url,
                name: name,
                byteSize: Int64(gb * 1_000_000_000),
                isDirectory: true,
                children: children,
                fileCount: max(children.count, Int(gb * 42))
            )
        }

        let developer = folder("Developer", 12.4, children: [
            file("DerivedData", 5.8, "cache"),
            file("Projects", 3.9, "swift"),
            file("Simulators", 2.7, "data")
        ])
        let media = folder("Media", 8.8, children: [
            file("Footage", 4.6, "mov"),
            file("Music", 2.4, "wav"),
            file("Photos", 1.8, "heic")
        ])
        let documents = folder("Documents", 4.1, children: [
            file("Archive", 2.1, "zip"),
            file("Design", 1.2, "fig"),
            file("Writing", 0.8, "pdf")
        ])
        let downloads = folder("Downloads", 2.7, children: [
            file("Installers", 1.6, "dmg"),
            file("Loose Files", 1.1, "data")
        ])
        let children = [developer, media, documents, downloads]

        return StorageNode(
            id: base,
            url: base,
            name: "Macintosh HD",
            byteSize: children.reduce(0) { $0 + $1.byteSize },
            isDirectory: true,
            children: children,
            fileCount: children.reduce(0) { $0 + $1.fileCount }
        )
    }
}
