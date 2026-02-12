import ARKit
import RealityKit

#if canImport(ObjectCapture)
import ObjectCapture
typealias AppObjectCaptureSession = ObjectCapture.ObjectCaptureSession
#else
typealias AppObjectCaptureSession = RealityKit.ObjectCaptureSession
#endif

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
        #if targetEnvironment(simulator)
        supportsObjectCapture = false
        missing.append("Physical device required (simulator not supported)")
        #else
        #if canImport(ObjectCapture) || canImport(RealityKit)
        supportsObjectCapture = AppObjectCaptureSession.isSupported
        #else
        supportsObjectCapture = false
        #endif
        if !supportsObjectCapture {
            missing.append("Object Capture")
        }
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
