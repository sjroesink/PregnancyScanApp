import RealityKit
#if canImport(ObjectCapture)
import ObjectCapture
#endif

#if canImport(ObjectCapture)
typealias AppObjectCaptureSession = ObjectCapture.ObjectCaptureSession
typealias AppObjectCaptureView = ObjectCapture.ObjectCaptureView
typealias AppObjectCapturePointCloudView = ObjectCapture.ObjectCapturePointCloudView
typealias AppPhotogrammetrySession = ObjectCapture.PhotogrammetrySession
#else
// Fallback for earlier versions or where it's in RealityKit
typealias AppObjectCaptureSession = ObjectCaptureSession
typealias AppObjectCaptureView = ObjectCaptureView
typealias AppObjectCapturePointCloudView = ObjectCapturePointCloudView
typealias AppPhotogrammetrySession = PhotogrammetrySession
#endif
