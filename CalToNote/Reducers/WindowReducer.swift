import ComposableArchitecture
import Combine

let windowReducer = Reducer<AppState, WindowAction, AppEnvironment> { state, action, environment in
    switch action {
    case let .registerPreferencesController(controller):
        state.windows.preferencesController = controller
        
    case .closeAndShowPreferencesWindow:
        return Publishers.Merge(
            Effect(value: WindowAction.hidePopover),
            Effect(value: WindowAction.showPreferencesWindow)
        ).eraseToEffect()
        
    case .showPreferencesWindow:
        state.windows.preferencesController?.show()

    case let .registerPopover(popover, monitor, button):
        state.windows.popover = popover
        state.windows.eventMonitor = monitor
        state.windows.statusBarButton = button
        
    case .hidePopover:
        state.windows.popover?.performClose(nil)
        state.windows.eventMonitor?.stop()
        
    case .showPopover:
        state.windows.popover?.show(
            relativeTo: state.windows.statusBarButton!.bounds,
            of: state.windows.statusBarButton!,
            preferredEdge: NSRectEdge.maxY
        )
        state.windows.eventMonitor?.start()
    }
    
    return .none
}
