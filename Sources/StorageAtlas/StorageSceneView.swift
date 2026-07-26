import AppKit
import SceneKit
import SwiftUI

struct StorageSceneView: NSViewRepresentable {
    let root: StorageNode
    @Binding var selected: StorageNode?
    let theme: AppTheme
    let onReveal: (StorageNode) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(selected: $selected, onReveal: onReveal)
    }

    func makeNSView(context: Context) -> InteractiveSceneView {
        let view = InteractiveSceneView()
        view.scene = SCNScene()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.rendersContinuously = true
        view.delegateBridge = context.coordinator
        context.coordinator.view = view
        context.coordinator.installCamera(in: view)
        context.coordinator.rebuild(root: root, theme: theme)
        return view
    }

    func updateNSView(_ view: InteractiveSceneView, context: Context) {
        context.coordinator.selected = $selected
        if context.coordinator.rootID != root.id || context.coordinator.theme != theme {
            context.coordinator.rebuild(root: root, theme: theme)
        }
        context.coordinator.highlight(selected?.id)
    }

    final class Coordinator: NSObject, InteractiveSceneDelegate {
        var selected: Binding<StorageNode?>
        let onReveal: (StorageNode) -> Void
        weak var view: SCNView?
        var cameraNode = SCNNode()
        var cameraTarget = SCNVector3Zero
        var rootID: URL?
        var theme: AppTheme?
        var nodes: [URL: SCNNode] = [:]
        var storageNodes: [URL: StorageNode] = [:]
        var lastSelectedID: URL?

        init(selected: Binding<StorageNode?>, onReveal: @escaping (StorageNode) -> Void) {
            self.selected = selected
            self.onReveal = onReveal
        }

        func installCamera(in view: SCNView) {
            let camera = SCNCamera()
            camera.fieldOfView = 48
            camera.zNear = 0.1
            camera.zFar = 1000
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 34, 45)
            view.scene?.rootNode.addChildNode(cameraNode)
            view.pointOfView = cameraNode

            let ambient = SCNLight()
            ambient.type = .ambient
            ambient.intensity = 520
            ambient.color = NSColor(calibratedWhite: 0.75, alpha: 1)
            let ambientNode = SCNNode()
            ambientNode.light = ambient
            view.scene?.rootNode.addChildNode(ambientNode)

            let key = SCNLight()
            key.type = .directional
            key.intensity = 1300
            key.castsShadow = true
            key.shadowRadius = 8
            let keyNode = SCNNode()
            keyNode.light = key
            keyNode.eulerAngles = SCNVector3(-0.9, 0.6, 0)
            view.scene?.rootNode.addChildNode(keyNode)
            lookAtTarget()
        }

        func rebuild(root: StorageNode, theme: AppTheme) {
            rootID = root.id
            self.theme = theme
            nodes.values.forEach { $0.removeFromParentNode() }
            nodes.removeAll()
            storageNodes.removeAll()
            guard let scene = view?.scene else { return }

            let floor = SCNFloor()
            floor.reflectivity = theme == .glass ? 0.18 : 0.04
            floor.reflectionFalloffEnd = 35
            floor.firstMaterial?.diffuse.contents = theme == .glass
                ? NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.10, alpha: 0.2)
                : NSColor(calibratedRed: 0.73, green: 0.76, blue: 0.81, alpha: 1)
            let floorNode = SCNNode(geometry: floor)
            floorNode.name = "floor"
            scene.rootNode.addChildNode(floorNode)
            nodes[URL(fileURLWithPath: "/__floor")] = floorNode

            let visible = Array(root.children.prefix(72))
            let rects = TreemapLayout.layout(nodes: visible, in: CGRect(x: -18, y: -13, width: 36, height: 26))
            for (node, rect) in rects {
                addBlock(node, rect: rect, theme: theme, to: scene.rootNode)
            }
        }

        private func addBlock(_ node: StorageNode, rect: CGRect, theme: AppTheme, to parent: SCNNode) {
            let inset: CGFloat = 0.14
            let width = max(0.25, rect.width - inset)
            let depth = max(0.25, rect.height - inset)
            let height = CGFloat(0.9 + min(7.5, log10(Double(max(10, node.byteSize))) * 0.72))
            let box = SCNBox(width: width, height: height, length: depth, chamferRadius: min(0.35, min(width, depth) * 0.08))
            let material = SCNMaterial()
            material.diffuse.contents = color(for: node, theme: theme)
            material.metalness.contents = theme == .glass ? 0.45 : 0.05
            material.roughness.contents = theme == .glass ? 0.25 : 0.72
            material.transparency = theme == .glass ? 0.90 : 1
            box.materials = [material]

            let block = SCNNode(geometry: box)
            block.position = SCNVector3(Float(rect.midX), Float(height / 2), Float(rect.midY))
            block.name = node.id.absoluteString
            block.categoryBitMask = 2
            parent.addChildNode(block)
            nodes[node.id] = block
            storageNodes[node.id] = node

            if node.isDirectory, rect.width > 3.2, rect.height > 2.6 {
                let children = Array(node.children.prefix(18))
                let childRect = CGRect(
                    x: rect.minX + 0.18, y: rect.minY + 0.18,
                    width: max(0, rect.width - 0.36), height: max(0, rect.height - 0.36)
                )
                let childLayouts = TreemapLayout.layout(nodes: children, in: childRect)
                for (child, childLayout) in childLayouts {
                    let childHeight = max(0.24, height * 0.12)
                    let childBox = SCNBox(
                        width: max(0.12, childLayout.width - 0.08),
                        height: childHeight,
                        length: max(0.12, childLayout.height - 0.08),
                        chamferRadius: 0.06
                    )
                    let childMaterial = SCNMaterial()
                    childMaterial.diffuse.contents = color(for: child, theme: theme).withAlphaComponent(0.92)
                    childMaterial.roughness.contents = 0.45
                    childBox.materials = [childMaterial]
                    let childNode = SCNNode(geometry: childBox)
                    childNode.position = SCNVector3(
                        Float(childLayout.midX),
                        Float(height + childHeight / 2 + 0.04),
                        Float(childLayout.midY)
                    )
                    childNode.name = child.id.absoluteString
                    childNode.categoryBitMask = 2
                    parent.addChildNode(childNode)
                    nodes[child.id] = childNode
                    storageNodes[child.id] = child
                }
            }
        }

        private func color(for node: StorageNode, theme: AppTheme) -> NSColor {
            let palette: [NSColor] = theme == .glass
                ? [.systemCyan, .systemIndigo, .systemPurple, .systemBlue, .systemTeal, .systemPink]
                : [
                    NSColor(calibratedRed: 0.38, green: 0.48, blue: 0.72, alpha: 1),
                    NSColor(calibratedRed: 0.52, green: 0.43, blue: 0.70, alpha: 1),
                    NSColor(calibratedRed: 0.31, green: 0.60, blue: 0.64, alpha: 1),
                    NSColor(calibratedRed: 0.70, green: 0.48, blue: 0.55, alpha: 1)
                ]
            return palette[abs(node.name.hashValue) % palette.count]
        }

        func clicked(at point: CGPoint, clickCount: Int) {
            guard let view else { return }
            let hits = view.hitTest(point, options: [
                .categoryBitMask: 2,
                .searchMode: SCNHitTestSearchMode.closest.rawValue
            ])
            guard let hit = hits.first,
                  let name = hit.node.name,
                  let id = URL(string: name),
                  let node = storageNodes[id] else { return }

            selected.wrappedValue = node
            highlight(id)
            if clickCount >= 2 {
                onReveal(node)
            } else {
                focus(on: hit.node)
            }
        }

        func dragged(deltaX: CGFloat, deltaY: CGFloat) {
            let offset = cameraNode.position - cameraTarget
            let radius = max(8, length(offset))
            var yaw = atan2(offset.x, offset.z)
            var pitch = asin(max(-1, min(1, offset.y / radius)))

            yaw -= deltaX * 0.008
            pitch = max(0.16, min(1.38, pitch + deltaY * 0.006))

            let horizontalRadius = radius * cos(pitch)
            cameraNode.position = SCNVector3(
                cameraTarget.x + horizontalRadius * sin(yaw),
                cameraTarget.y + radius * sin(pitch),
                cameraTarget.z + horizontalRadius * cos(yaw)
            )
            lookAtTarget()
        }

        func scrolled(delta: CGFloat) {
            let direction = normalized(cameraTarget - cameraNode.position)
            let distance = length(cameraTarget - cameraNode.position)
            let step = delta * 0.035
            if (distance > 8 || step < 0), (distance < 95 || step > 0) {
                cameraNode.position = cameraNode.position + direction * step
            }
        }

        func highlight(_ id: URL?) {
            guard lastSelectedID != id else { return }
            if let lastSelectedID, let old = nodes[lastSelectedID] {
                old.geometry?.firstMaterial?.emission.contents = NSColor.black
            }
            if let id, let current = nodes[id] {
                current.geometry?.firstMaterial?.emission.contents = NSColor.white.withAlphaComponent(0.23)
            }
            lastSelectedID = id
        }

        private func focus(on node: SCNNode) {
            let target = node.presentation.worldPosition
            cameraTarget = SCNVector3(target.x, 0.8, target.z)
            let destination = SCNVector3(target.x + 8, max(10, target.y + 10), target.z + 13)
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.65
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            cameraNode.position = destination
            lookAtTarget()
            SCNTransaction.commit()
        }

        private func lookAtTarget() {
            cameraNode.look(at: cameraTarget, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        }

        private func normalized(_ vector: SCNVector3) -> SCNVector3 {
            let l = max(0.001, length(vector))
            return SCNVector3(vector.x / l, vector.y / l, vector.z / l)
        }

        private func length(_ vector: SCNVector3) -> CGFloat {
            let xx = vector.x * vector.x
            let yy = vector.y * vector.y
            let zz = vector.z * vector.z
            return sqrt(xx + yy + zz)
        }
    }
}

fileprivate protocol InteractiveSceneDelegate: AnyObject {
    func clicked(at point: CGPoint, clickCount: Int)
    func dragged(deltaX: CGFloat, deltaY: CGFloat)
    func scrolled(delta: CGFloat)
}

final class InteractiveSceneView: SCNView {
    fileprivate weak var delegateBridge: InteractiveSceneDelegate?
    private var lastPoint: CGPoint?
    private var didDrag = false

    override func mouseDown(with event: NSEvent) {
        lastPoint = convert(event.locationInWindow, from: nil)
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let lastPoint {
            delegateBridge?.dragged(deltaX: point.x - lastPoint.x, deltaY: point.y - lastPoint.y)
            didDrag = true
        }
        lastPoint = point
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if !didDrag {
            delegateBridge?.clicked(at: point, clickCount: event.clickCount)
        }
        lastPoint = nil
    }

    override func scrollWheel(with event: NSEvent) {
        delegateBridge?.scrolled(delta: event.scrollingDeltaY)
    }
}

enum TreemapLayout {
    static func layout(nodes: [StorageNode], in rect: CGRect) -> [(StorageNode, CGRect)] {
        guard !nodes.isEmpty, rect.width > 0, rect.height > 0 else { return [] }
        if nodes.count == 1 {
            return [(nodes[0], rect)]
        }

        let total = nodes.reduce(Int64(0)) { $0 + max(1, $1.byteSize) }
        var leadingTotal: Int64 = 0
        var splitIndex = 1
        for index in 0..<(nodes.count - 1) {
            leadingTotal += max(1, nodes[index].byteSize)
            splitIndex = index + 1
            if leadingTotal * 2 >= total { break }
        }

        let ratio = CGFloat(Double(leadingTotal) / Double(max(1, total)))
        let leadingNodes = Array(nodes[..<splitIndex])
        let trailingNodes = Array(nodes[splitIndex...])
        let leadingRect: CGRect
        let trailingRect: CGRect

        if rect.width >= rect.height {
            let split = rect.width * ratio
            leadingRect = CGRect(x: rect.minX, y: rect.minY, width: split, height: rect.height)
            trailingRect = CGRect(x: rect.minX + split, y: rect.minY,
                                  width: rect.width - split, height: rect.height)
        } else {
            let split = rect.height * ratio
            leadingRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: split)
            trailingRect = CGRect(x: rect.minX, y: rect.minY + split,
                                  width: rect.width, height: rect.height - split)
        }

        return layout(nodes: leadingNodes, in: leadingRect)
            + layout(nodes: trailingNodes, in: trailingRect)
    }
}

private func + (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

private func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
}

private func * (lhs: SCNVector3, rhs: CGFloat) -> SCNVector3 {
    SCNVector3(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
}
