import XCTest
@testable import StorageAtlas

final class TreemapLayoutTests: XCTestCase {
    func testLayoutPreservesBoundsAndOrder() {
        let base = URL(fileURLWithPath: "/tmp")
        let nodes = [
            StorageNode(id: base.appendingPathComponent("A"), url: base.appendingPathComponent("A"),
                        name: "A", byteSize: 75, isDirectory: true, children: [], fileCount: 1),
            StorageNode(id: base.appendingPathComponent("B"), url: base.appendingPathComponent("B"),
                        name: "B", byteSize: 25, isDirectory: true, children: [], fileCount: 1)
        ]
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let result = TreemapLayout.layout(nodes: nodes, in: rect)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].1.width, 75, accuracy: 0.01)
        XCTAssertEqual(result[1].1.maxX, rect.maxX, accuracy: 0.01)
    }
}
