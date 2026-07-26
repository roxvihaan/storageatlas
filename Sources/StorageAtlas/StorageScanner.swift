import Foundation

enum StorageScanner {
    private struct MutableDirectory {
        var directBytes: Int64 = 0
        var directFiles: [StorageNode] = []
    }

    static func scan(url: URL) async throws -> StorageNode {
        try await Task.detached(priority: .userInitiated) {
            try scanSynchronously(url: url)
        }.value
    }

    private static func scanSynchronously(url: URL) throws -> StorageNode {
        try Task.checkCancellation()
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey, .isRegularFileKey, .fileSizeKey,
            .totalFileAllocatedSizeKey, .isSymbolicLinkKey, .isHiddenKey
        ]
        let manager = FileManager.default
        let options: FileManager.DirectoryEnumerationOptions = [
            .skipsPackageDescendants, .skipsHiddenFiles
        ]
        guard let enumerator = manager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: options,
            errorHandler: { _, _ in true }
        ) else {
            throw CocoaError(.fileReadNoSuchFile)
        }

        var directories: [URL: MutableDirectory] = [url: MutableDirectory()]

        for case let itemURL as URL in enumerator {
            try Task.checkCancellation()
            let values = try? itemURL.resourceValues(forKeys: keys)
            if values?.isSymbolicLink == true { continue }
            if values?.isDirectory == true {
                directories[itemURL] = directories[itemURL] ?? MutableDirectory()
                continue
            }
            guard values?.isRegularFile == true else { continue }
            let size = Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
            let file = StorageNode(
                id: itemURL,
                url: itemURL,
                name: itemURL.lastPathComponent,
                byteSize: size,
                isDirectory: false,
                children: [],
                fileCount: 1
            )
            let parent = itemURL.deletingLastPathComponent()
            directories[parent, default: MutableDirectory()].directBytes += size
            directories[parent, default: MutableDirectory()].directFiles.append(file)
        }

        let orderedDirectories = directories.keys.sorted {
            $0.pathComponents.count > $1.pathComponents.count
        }
        var built: [URL: StorageNode] = [:]

        for directoryURL in orderedDirectories {
            let direct = directories[directoryURL] ?? MutableDirectory()
            let folders = built.values.filter {
                $0.url.deletingLastPathComponent() == directoryURL
            }
            let children = (folders + direct.directFiles)
                .sorted { $0.byteSize > $1.byteSize }
            let bytes = direct.directBytes + folders.reduce(0) { $0 + $1.byteSize }
            let count = direct.directFiles.count + folders.reduce(0) { $0 + $1.fileCount }
            built[directoryURL] = StorageNode(
                id: directoryURL,
                url: directoryURL,
                name: directoryURL.lastPathComponent,
                byteSize: bytes,
                isDirectory: true,
                children: Array(children.prefix(160)),
                fileCount: count
            )
        }

        return built[url] ?? StorageNode(
            id: url, url: url, name: url.lastPathComponent,
            byteSize: 0, isDirectory: true, children: [], fileCount: 0
        )
    }
}
