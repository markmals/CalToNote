import SwiftUI
import Preferences

import ComposableArchitecture

struct ContentView: View {
    let store: AppStore

    var body: some View {
        WithViewStore(store) { viewStore in
            if !viewStore.state.templateIsSet {
                VStack(alignment: .center) {
                    Text("Welcome to CalToNote")
                        .font(.system(
                            size: 24,
                            weight: .bold,
                            design: .rounded
                        ))
                        .padding(.bottom, 6)
                    
                    Text("CalToNote creates a Boxnote in the folder of your choosing for every calendar event you have with a certain criteria.")
                        .font(.subheadline)
                        .opacity(0.75)
                        .padding(.bottom, 20)

                    Text("To proceede, please select a template file to use when creating new notes for events:")
                    Button("Select Template") { viewStore.send(.selectTemplate) }
                    Spacer()
                }
                .padding(24)
            } else {
                ScrollView {
                    HStack {
                        Text("CalToNote")
                            .font(.system(
                                size: 24,
                                weight: .bold,
                                design: .rounded
                            ))
                            .padding(.bottom, 6)
                        
                        Spacer()
                        
                        Button { viewStore.send(.showPreferencesWindow) }
                        label: {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    if !viewStore.state.events.isEmpty {
                        ForEach(viewStore.state.events) { event in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("\(format(event.startDate)) - \(formatWithPeriod(event.endDate))")
                                        .opacity(0.4)
                                    
                                    Text(event.title).bold()
                                }
                                .padding()

                                Spacer()

                                Button("Create Note") { viewStore.send(.createNote(from: event)) }
                            }
                        }
                    } else {
                        Text("No More Events Today")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                }
                .padding(24)
            }
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
}
