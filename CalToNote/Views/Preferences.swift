import SwiftUI
import Preferences
import ComposableArchitecture

struct GeneralPreferencePane: View {
    let store: AppStore
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Preferences.Container(contentWidth: 377) {
                Preferences.Section(title: "Template:") {
                    Button("Show Template") { viewStore.send(.showTemplate) }
                    Button("Replace Template") { viewStore.send(.selectTemplate) }
                    Text("The template is copied in order to create a new note for events. You can create a blank .boxnote and set it as the template")
                        .preferenceDescription()
                }
                
                Preferences.Section(label: {
                    Toggle("Show notifications:", isOn: viewStore.binding(
                            get: \.userWantsToReceiveNotifications,
                            send: .toggleSendNotifications
                    ))
                }) {
                    Group {
                        Text("Which calendar?")
                        Picker("Select Calendar", selection: viewStore.binding(
                            get: \.selectedCalendar,
                            send: AppAction.selectCalendar
                        )) {
                            ForEach(viewStore.state.calendars) { calendar in
                                Text(calendar.title).tag(calendar.title)
                            }
                        }
                        .padding(.bottom, 6)
//                        .onAppear(perform: calObservable.fetch)
                        
                        Text("Only for events with this keyword in its notes:")
                        TextField("", text: viewStore.binding(
                            get: \.filterKeyword,
                            send: AppAction.updateFilterKeyword
                        ))
                        .padding(.bottom, 6)
                        
//                        Text("Fetch calendar events:")
//                        Picker("Select Calendar", selection: $fetchInterval) {
//                            Text("Every 15 minutes")
//                                .tag(Notifications.Interval.fifteenMinutes)
//                            Text("Every 30 minutes")
//                                .tag(Notifications.Interval.thirtyMinutes)
//                            Text("Every 45 minutes")
//                                .tag(Notifications.Interval.fourtyFiveMinutes)
//                            Text("Every hour")
//                                .tag(Notifications.Interval.oneHour)
//                        }
                    }
                    .disabled(!viewStore.state.userWantsToReceiveNotifications)
                    
                    if !viewStore.state.userAllowedNotifications {
                        Text("You have denied notifications permissions. Please allow notifications permissions in System Preferences to configure notification settings here.")
                    }
                }
            }

        }
    }
}
