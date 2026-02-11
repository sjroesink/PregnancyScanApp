import SceneKit
import ModelIO
import UIKit

final class ThumbnailService {

    func generateThumbnail(
        from modelURL: URL,
        size: CGSize = CGSize(width: 256, height: 256)
    ) -> UIImage? {
        let mdlAsset = MDLAsset(url: modelURL)
        mdlAsset.loadTextures()

        let scene = SCNScene(mdlAsset: mdlAsset)

        let scnView = SCNView(frame: CGRect(origin: .zero, size: size))
        scnView.scene = scene
        scnView.autoenablesDefaultLighting = true
        scnView.backgroundColor = .systemBackground

        // Center the model
        let (minBound, maxBound) = scene.rootNode.boundingBox
        let center = SCNVector3(
            (minBound.x + maxBound.x) / 2,
            (minBound.y + maxBound.y) / 2,
            (minBound.z + maxBound.z) / 2
        )
        let maxDim = max(
            maxBound.x - minBound.x,
            max(maxBound.y - minBound.y, maxBound.z - minBound.z)
        )
        if maxDim > 0 {
            let scale = 2.0 / maxDim
            scene.rootNode.scale = SCNVector3(scale, scale, scale)
            scene.rootNode.position = SCNVector3(
                -center.x * scale,
                -center.y * scale,
                -center.z * scale
            )
        }

        // Position camera
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0.5, 3)
        cameraNode.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(cameraNode)

        return scnView.snapshot()
    }

    func saveThumbnail(_ image: UIImage, to url: URL) throws {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try data.write(to: url)
    }
}
