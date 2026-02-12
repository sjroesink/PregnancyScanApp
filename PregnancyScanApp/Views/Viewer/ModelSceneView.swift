import SwiftUI
import SceneKit
import SceneKit.ModelIO
import ModelIO

struct ModelSceneView: UIViewRepresentable {

    let modelURL: URL

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = .systemBackground
        scnView.antialiasingMode = .multisampling4X

        loadModel(into: scnView)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    private func loadModel(into scnView: SCNView) {
        let mdlAsset = MDLAsset(url: modelURL)
        mdlAsset.loadTextures()

        let scene = SCNScene(mdlAsset: mdlAsset)

        // Center and scale the model
        let (minBound, maxBound) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minBound.x + maxBound.x) / 2,
            (minBound.y + maxBound.y) / 2,
            (minBound.z + maxBound.z) / 2
        )

        let size = SCNVector3(
            maxBound.x - minBound.x,
            maxBound.y - minBound.y,
            maxBound.z - minBound.z
        )
        let maxDimension = max(size.x, max(size.y, size.z))

        if maxDimension > 0 {
            let scaleFactor = 2.0 / maxDimension
            scene.rootNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            scene.rootNode.position = SCNVector3(
                -center.x * scaleFactor,
                -center.y * scaleFactor,
                -center.z * scaleFactor
            )
        }

        // Add a subtle floor grid
        let floor = SCNFloor()
        floor.reflectivity = 0.05
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(0, Float(minBound.y * (2.0 / maxDimension)), 0)
        scene.rootNode.addChildNode(floorNode)

        scnView.scene = scene
    }
}
