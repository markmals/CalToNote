import Foundation

enum FilePath {
    static let template = FileManager
        .default
        .urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )
        .last!
        .appendingPathComponent("Template.boxnote")
}
