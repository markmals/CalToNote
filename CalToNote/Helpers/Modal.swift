import Cocoa
import Defaults

enum Modal {
    static func chooseDocument(
        title: String,
        canChooseFiles: Bool = true,
        canChooseDirectories: Bool = false,
        allowedFileTypes: [String] = []
    ) -> Result<URL, Error> {
        let openPanel = NSOpenPanel()
        
        openPanel.title = title
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = canChooseDirectories
        openPanel.canChooseFiles = canChooseFiles
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = allowedFileTypes
        
        let shouldChooseDocument = openPanel.runModal() == .OK
        let itemURL = openPanel.url
        
        return shouldChooseDocument ?
            .success(itemURL!) :
            .failure(CalToNoteError.userCancelled)
    }

    static func alert(forError error: Error) {
        let alert = NSAlert()
        
        alert.messageText = "Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    static func setTemplate() {
        do {
            let url = try Modal
                .chooseDocument(
                    title: "Choose A Boxnote Template File",
                    allowedFileTypes: ["boxnote"]
                )
                .get()
            
            if let contents = try? Data(contentsOf: url) {
                // Throw an error if the `.boxnote` file is an invalid format
                _ = try JSONDecoder().decode(Boxnote.self, from: contents)
                
                // If a template already exists, delete it
                if FileManager.default.fileExists(atPath: FilePath.template.path) {
                    try FileManager.default.removeItem(at: FilePath.template)
                }
                
                // Copy the newly selected template to its location
                try FileManager.default.copyItem(at: url, to: FilePath.template)
            }
            
            Defaults[.templateIsSet] = true
        } catch {
            Modal.alert(forError: error)
        }
    }
}
