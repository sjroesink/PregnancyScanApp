import Foundation

enum AppConstants {
    static let scansRootDirectoryName = "Scans"
    static let imagesDirectoryName = "Images"
    static let snapshotsDirectoryName = "Snapshots"
    static let modelsDirectoryName = "Models"
    static let exportsDirectoryName = "Exports"

    static let modelFileName = "model"
    static let usdzExtension = "usdz"
    static let objExtension = "obj"
    static let stlExtension = "stl"

    static let minimumRecommendedImages = 30
    static let maximumRecommendedImages = 100

    static let scanPassCount = 3

    enum ScanPassGuidance {
        static let lowPassTitle = "Lower Torso"
        static let lowPassDescription = "Scan around the lower torso at waist level"
        static let midPassTitle = "Center Torso"
        static let midPassDescription = "Now scan at belly/center level"
        static let highPassTitle = "Upper Torso"
        static let highPassDescription = "Finally, scan the upper torso/chest area"
    }

    enum SubjectGuidance {
        static let holdStill = "Please stand still and breathe normally"
        static let armsAway = "Keep arms slightly away from body"
        static let faceForward = "Face forward and remain relaxed"
        static let countdown = "Starting scan in"
    }
}
