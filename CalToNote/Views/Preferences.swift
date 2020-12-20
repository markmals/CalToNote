import SwiftUI
import Defaults
import Preferences
import EventKit

extension Defaults.Keys {
    static let shouldShowNotifications = Key<Bool>("shouldShowNotifications", default: false)
    static let filterKeyword = Key<String>("filterKeyword", default: "meeting")
    static let fetchInterval = Key<Notifications.Interval>("fetchInterval", default: .fifteenMinutes)
    static let selectedCalendar = Key<String>("selectedCalendar", default: "")
}

extension EKCalendar: Identifiable {
    public var id: String {
        self.calendarIdentifier
    }
}

final class CalendarObservable: ObservableObject {
    let store: EKEventStore
    init(store: EKEventStore) { self.store = store }
    @Published var calendars: [EKCalendar] = []
    func fetch() { calendars = store.calendars(for: .event) }
}

struct GeneralPreferencePane: View {
    @Default(.shouldShowNotifications) private var shouldShowNotifications
    @Default(.filterKeyword) private var filterKeyword
    @Default(.fetchInterval) private var fetchInterval
    @Default(.selectedCalendar) private var selectedCalendar
    @EnvironmentObject private var calObservable: CalendarObservable
    
    func setTemplate() {
        Modal.setTemplate()
    }
    
    func showTemplate() {
        NSWorkspace.shared.selectFile(
            FilePath.template.path,
            inFileViewerRootedAtPath: FilePath.template.deletingLastPathComponent().path
        )
    }
    
    var body: some View {
        Preferences.Container(contentWidth: 377) {
            Preferences.Section(title: "Template:") {
                Button("Show Template", action: showTemplate)
                Button("Replace Template", action: setTemplate)
                Text("The template is copied in order to create a new note for events. You can create a blank .boxnote and set it as the template")
                    .preferenceDescription()
            }
            
            Preferences.Section(label: {
                Toggle("Show notifications:", isOn: $shouldShowNotifications)
            }) {
                Group {
                    Text("Which calendar?")
                    Picker("Select Calendar", selection: $selectedCalendar) {
                        ForEach(calObservable.calendars) { calendar in
                            Text(calendar.title).tag(calendar.title)
                        }
                    }
                    .padding(.bottom, 6)
                    .onAppear(perform: calObservable.fetch)
                    
                    Text("Only for events with this keyword in its notes:")
                    TextField("", text: $filterKeyword)
                        .padding(.bottom, 6)
                    
                    Text("Fetch calendar events:")
                    Picker("Select Calendar", selection: $fetchInterval) {
                        Text("Every 15 minutes")
                            .tag(Notifications.Interval.fifteenMinutes)
                        Text("Every 30 minutes")
                            .tag(Notifications.Interval.thirtyMinutes)
                        Text("Every 45 minutes")
                            .tag(Notifications.Interval.fourtyFiveMinutes)
                        Text("Every hour")
                            .tag(Notifications.Interval.oneHour)
                    }
                }
                .disabled(!shouldShowNotifications)
            }
        }
    }
}
