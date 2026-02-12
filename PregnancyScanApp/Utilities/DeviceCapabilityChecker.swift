import ARKit
import RealityKit

@available(iOS 17.0, *)
enum DeviceCapabilityChecker {

    struct CapabilityResult {
        let isSupported: Bool
        let hasLiDAR: Bool
        let supportsObjectCapture: Bool
        let missingCapabilities: [String]
    }

    static func checkCapabilities() -> CapabilityResult {
        var missing: [String] = []

        let hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        if !hasLiDAR {
            missing.append("LiDAR Scanner")
        }

        #if ENABLE_OBJECT_CAPTURE
        let supportsObjectCapture = RealityKit.ObjectCaptureSession.isSupported
        #else
        let supportsObjectCapture = false
        #endif
        if !supportsObjectCapture {
            missing.append("Object Capture")
        }

        let isSupported = hasLiDAR && supportsObjectCapture

        return CapabilityResult(
            isSupported: isSupported,
            hasLiDAR: hasLiDAR,
            supportsObjectCapture: supportsObjectCapture,
            missingCapabilities: missing
        )
    }
}
