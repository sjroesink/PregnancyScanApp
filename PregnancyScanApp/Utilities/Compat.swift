import RealityKit
#if canImport(ObjectCapture)
import ObjectCapture
#endif
#if canImport(_RealityKit_SwiftUI)
import _RealityKit_SwiftUI
#endif

#if canImport(ObjectCapture)
typealias AppObjectCaptureSession = ObjectCapture.ObjectCaptureSession
typealias AppObjectCaptureView = ObjectCapture.ObjectCaptureView
typealias AppObjectCapturePointCloudView = ObjectCapture.ObjectCapturePointCloudView
typealias AppPhotogrammetrySession = ObjectCapture.PhotogrammetrySession
#elseif canImport(_RealityKit_SwiftUI)
typealias AppObjectCaptureSession = _RealityKit_SwiftUI.ObjectCaptureSession
typealias AppObjectCaptureView = _RealityKit_SwiftUI.ObjectCaptureView
typealias AppObjectCapturePointCloudView = _RealityKit_SwiftUI.ObjectCapturePointCloudView
typealias AppPhotogrammetrySession = RealityKit.PhotogrammetrySession
#else
// Fallback for earlier versions or where it's in RealityKit
typealias AppObjectCaptureSession = RealityKit.ObjectCaptureSession
typealias AppObjectCaptureView = RealityKit.ObjectCaptureView
typealias AppObjectCapturePointCloudView = RealityKit.ObjectCapturePointCloudView
typealias AppPhotogrammetrySession = RealityKit.PhotogrammetrySession
#endif
