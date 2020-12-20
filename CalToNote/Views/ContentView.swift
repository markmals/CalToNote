import SwiftUI
import Defaults
import EventKit
import Preferences

extension Defaults.Keys {
    static let templateIsSet = Key<Bool>("templateIsSet", default: false)
    static let isFirstLaunch = Key<Bool>("isFirstLaunch", default: true)
}

struct ContentView: View {
    let hidePopover: () -> Void
    
    @EnvironmentObject var prefWindow: PreferencesWindowController
    @EnvironmentObject var eventFetcher: Events
    
    @Default(.templateIsSet) var templateIsSet: Bool
    @Default(.isFirstLaunch) var isFirstLaunch: Bool
    
    var body: some View {
            if !templateIsSet {
                VStack(alignment: .center) {
                    Text("Welcome to CalToNote").font(.system(size: 24, weight: .bold, design: .rounded)).padding(.bottom, 6)
                    Text("CalToNote creates a Boxnote in the folder of your choosing for every calendar event you have with a certain criteria.").font(.subheadline).opacity(0.75).padding(.bottom, 20)
                
                    Text("To proceede, please select a template file to use when creating new notes for events:")
                    Button("Select Template", action: selectTemplate)
                    
                    Spacer()
                }.padding(24)
            } else if let events = eventFetcher.cachedEvents {
                ScrollView {
                    HStack {
                        Text("CalToNote").font(.system(size: 24, weight: .bold, design: .rounded)).padding(.bottom, 6)
                        Spacer()
                        Button {
                            prefWindow.show()
                            hidePopover()
                        }
                        label: {
                            Group {
                                if #available(OSX 11.0, *) {
                                    Image(systemName: "gear")
                                } else {
                                    Image("gear")
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        // FIXME: Figure out how to make this backwards compatible
                        // .keyboardShortcut(",", modifiers: .command)
                    }
                    
                    if !events.isEmpty {
                        ForEach(events, id: \.eventIdentifier) { event in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(format(event.startDate)) - \(formatWithPeriod(event.endDate))")
                                        .opacity(0.4)
                                    
                                    Text(event.title).bold()
                                }.padding()
                                
                                Spacer()
                                
                                Button("Create Note") { createNote(event) }
                            }
                        }
                    } else {
                        Text("No More Events Today")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                }.padding(24)
            } else {
                Text("ERROR")
            }
    }
    
    func formatWithPeriod(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
    
    func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
    
    func createNote(_ event: EKEvent) {
        hidePopover()
        
        do {
            let url = try Modal
                .chooseDocument(
                    title: "Where Would You Like to Create this Note?",
                    canChooseFiles: false,
                    canChooseDirectories: true
                )
                .get()
            
            let formatter = DateFormatter(dateFormat: "yyyy-MM-dd HH.mm.ss")
            let tempTitle = "CalToNote Untitled Event \(formatter.string(from: Date()))"
            let destination = url.appendingPathComponent("\(event.title ?? tempTitle).boxnote")
            try FileManager.default.copyItem(at: FilePath.template, to: destination)
        } catch {
            Modal.alert(forError: error)
        }
    }
    
    func selectTemplate() {
        hidePopover()
         
        do {
            let url = try Modal
                .chooseDocument(
                    title: "Choose A Boxnote Template File",
                    allowedFileTypes: ["boxnote"]
                )
                .get()
            
            try setTemplateDocument(at: url)
            templateIsSet = true
        } catch {
            Modal.alert(forError: error)
        }
    }
    
    private func setTemplateDocument(at url: URL) throws {
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
    }
}
