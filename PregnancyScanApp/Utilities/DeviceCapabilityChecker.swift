import ARKit
import RealityKit

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

        let supportsObjectCapture: Bool
        #if ENABLE_OBJECT_CAPTURE
        supportsObjectCapture = ObjectCaptureSession.isSupported
        if !supportsObjectCapture {
            missing.append("Object Capture")
        }
        #else
        supportsObjectCapture = false
        missing.append("Object Capture not included in this build")
        #endif

        let isSupported = hasLiDAR && supportsObjectCapture

        return CapabilityResult(
            isSupported: isSupported,
            hasLiDAR: hasLiDAR,
            supportsObjectCapture: supportsObjectCapture,
            missingCapabilities: missing
        )
    }
}
