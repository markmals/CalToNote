import ComposableArchitecture

let preferenceReducer = Reducer<AppState, PreferenceAction, AppEnvironment> { state, action, environment in
    switch action {
    case .selectTemplate:
        do {
            let url = try environment.fileClient.chooseDocument(
                title: "Choose A Boxnote Template File",
                canChooseFiles: true,
                canChooseDirectories: false,
                allowedFileTypes: ["boxnote"]
            )
            
            try environment.fileClient.setTemplateDocument(at: url)
            state.templateIsSet = true
        } catch {
//            return Effect(value: AppAction.presentError(error))
        }

    case .showTemplate:
        environment.fileClient.showFile(at: FilePath.template)

    case .toggleSendNotifications:
        state.notifications.userWantsToReceiveNotifications.toggle()

    case let .updateFilterKeyword(keyword):
        state.filterKeyword = keyword
    // Every time the "filter keyword" setting is changed, update the event cache
    //        return AppAction.updateCalendar
        
    case let .selectCalendar(calendar):
        state.selectedCalendar = calendar
        // Every time the "selected calendar" setting is changed, update the event cache
    //        return AppAction.updateCalendar
    }
    
    return .none
}
