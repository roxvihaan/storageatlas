import AppKit
import Foundation
import SwiftUI

struct StorageNode: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let name: String
    let byteSize: Int64
    let isDirectory: Bool
    let children: [StorageNode]
    let fileCount: Int

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
    }

    var extensionName: String {
        isDirectory ? "Folder" : (url.pathExtension.isEmpty ? "Other" : url.pathExtension.uppercased())
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case glass
    case neumorphic

    var id: String { rawValue }
    var title: String { self == .glass ? "Glass" : "Neumorphic" }
    var symbol: String { self == .glass ? "sparkles.rectangle.stack" : "square.stack.3d.up.fill" }
}

@MainActor
final class StorageModel: ObservableObject {
    @Published var root: StorageNode?
    @Published var selected: StorageNode?
    @Published var isScanning = false
    @Published var scanProgress = "Choose a folder to begin"
    @Published var theme: AppTheme = .glass
    @Published var errorMessage: String?
    @Published var showOnboarding = false

    private var scanTask: Task<Void, Never>?

    func chooseAndScan() {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder to map"
        panel.prompt = "Map Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        scan(url: url)
    }

    func scan(url: URL) {
        scanTask?.cancel()
        isScanning = true
        errorMessage = nil
        scanProgress = "Reading \(url.lastPathComponent)…"

        scanTask = Task {
            do {
                let node = try await StorageScanner.scan(url: url)
                guard !Task.isCancelled else { return }
                root = node
                selected = node
                scanProgress = "\(node.fileCount.formatted()) items mapped"
                isScanning = false
            } catch is CancellationError {
                isScanning = false
            } catch {
                errorMessage = error.localizedDescription
                scanProgress = "Couldn’t finish the scan"
                isScanning = false
            }
        }
    }

    func reveal(_ node: StorageNode? = nil) {
        guard let target = node ?? selected else { return }
        NSWorkspace.shared.activateFileViewerSelecting([target.url])
    }
}
