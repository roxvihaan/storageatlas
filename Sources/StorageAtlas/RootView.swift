import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: StorageModel

    var body: some View {
        ZStack {
            ThemedBackground(theme: model.theme)
            HStack(spacing: 10) {
                SidebarView()
                    .frame(width: 286)
                    .frame(maxHeight: .infinity)

                mainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 10)
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(model.theme == .glass ? .dark : .light)
        .foregroundStyle(model.theme == .glass ? Color.white : Color(red: 0.15, green: 0.18, blue: 0.24))
        .toolbar {
            ToolbarItemGroup {
                Picker("Theme", selection: $model.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Label(theme.title, systemImage: theme.symbol).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)
                Button {
                    model.chooseAndScan()
                } label: {
                    Label("Scan Folder", systemImage: "folder.badge.plus")
                }
            }
        }
        .alert("Storage Atlas", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if let root = model.root {
                StorageSceneView(root: root, selected: $model.selected, theme: model.theme) {
                    model.reveal($0)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(alignment: .topLeading) {
                    sceneHeader(root)
                }
                .overlay(alignment: .bottomTrailing) {
                    interactionHint
                }
            } else {
                emptyState
            }
            if model.isScanning {
                scanningOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .themedSurface(model.theme, cornerRadius: 24)
    }

    private func sceneHeader(_ root: StorageNode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(root.name)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text("\(root.formattedSize) · \(root.fileCount.formatted()) files")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
    }

    private var interactionHint: some View {
        Label("Click to focus · Double-click to reveal · Drag to rotate · Scroll to zoom",
              systemImage: "cursorarrow.motionlines")
            .font(.caption)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(.black.opacity(model.theme == .glass ? 0.35 : 0.08), in: Capsule())
            .padding(14)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 68))
                .symbolRenderingMode(.hierarchical)
            VStack(spacing: 7) {
                Text("See your storage as a landscape")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Pick a folder and Storage Atlas will turn its contents into an explorable 3D map.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }
            Button("Choose a Folder…") { model.chooseAndScan() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    private var scanningOverlay: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(model.scanProgress)
                .font(.headline)
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct SidebarView: View {
    @EnvironmentObject private var model: StorageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "square.3.layers.3d.top.filled")
                    .font(.title2)
                    .foregroundStyle(model.theme == .glass ? .cyan : .indigo)
                Text("Storage Atlas")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
            }

            Divider()
            if let selected = model.selected {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SELECTION")
                        .font(.caption2.bold())
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                    Image(systemName: selected.isDirectory ? "folder.fill" : "doc.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(model.theme == .glass ? .cyan : .indigo)
                    Text(selected.name)
                        .font(.headline)
                        .lineLimit(2)
                    metric("Size", selected.formattedSize)
                    metric("Type", selected.extensionName)
                    if selected.isDirectory {
                        metric("Files", selected.fileCount.formatted())
                    }
                    Button {
                        model.reveal(selected)
                    } label: {
                        Label("Show in Finder", systemImage: "finder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Click a block to inspect it.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(model.scanProgress)
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                model.chooseAndScan()
            } label: {
                Label("Map Another Folder", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .themedSurface(model.theme)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
