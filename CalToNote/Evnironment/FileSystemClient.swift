import Foundation
import Cocoa
import ComposableArchitecture

protocol FileSystemEnvironment {
    func fileExists(at path: String) -> Bool
    func copy(from source: String, to destination: String) throws
    func copy(from source: URL, to destination: URL) throws
    
    func chooseDocument(
        title: String,
        canChooseFiles: Bool,
        canChooseDirectories: Bool,
        allowedFileTypes: [String]
    ) throws -> URL
    
    func setTemplateDocument(at url: URL) throws
    func showFile(at url: URL)
}

struct FileSystemClient: FileSystemEnvironment {
    let fileManager = FileManager.default
    
    func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    func copy(from source: String, to destination: String) throws {
        try fileManager.copyItem(atPath: source, toPath: destination)
    }
    
    func copy(from source: URL, to destination: URL) throws {
        try fileManager.copyItem(at: source, to: destination)
    }
    
    func chooseDocument(
        title: String,
        canChooseFiles: Bool = true,
        canChooseDirectories: Bool = false,
        allowedFileTypes: [String] = []
    ) throws -> URL {
        let openPanel = NSOpenPanel()
        openPanel.title = title
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = canChooseDirectories
        openPanel.canChooseFiles = canChooseFiles
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = allowedFileTypes
        
        guard openPanel.runModal() == .OK else {
            throw CalToNoteError.userCancelled
        }
        
        return openPanel.url!
    }
    
    func setTemplateDocument(at url: URL) throws {
        if let contents = try? Data(contentsOf: url) {
            // Throw an error if the `.boxnote` file is an invalid format
            _ = try JSONDecoder().decode(Boxnote.self, from: contents)

            // If a template already exists, delete it
            if fileExists(at: FilePath.template.path) {
                try fileManager.removeItem(at: FilePath.template)
            }

            // Copy the newly selected template to its location
            try copy(from: url.path, to: FilePath.template.path)
        }
    }
    
    func showFile(at url: URL) {
        NSWorkspace.shared.selectFile(url.path,
            inFileViewerRootedAtPath: url.deletingLastPathComponent().path
        )
    }
}
