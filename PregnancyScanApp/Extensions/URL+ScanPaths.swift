import Foundation

extension URL {

    var imagesDirectory: URL {
        appending(path: AppConstants.imagesDirectoryName)
    }

    var snapshotsDirectory: URL {
        appending(path: AppConstants.snapshotsDirectoryName)
    }

    var modelsDirectory: URL {
        appending(path: AppConstants.modelsDirectoryName)
    }

    var exportsDirectory: URL {
        appending(path: AppConstants.exportsDirectoryName)
    }

    func modelFile(format: ExportFormat) -> URL {
        modelsDirectory.appending(path: format.fileName())
    }
}
