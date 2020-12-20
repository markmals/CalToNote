import Foundation
import EventKit
import Combine

final class Events: ObservableObject {
    private let store: EKEventStore
    private var predicate: NSPredicate
    private var transform: ([EKEvent]) -> [EKEvent]
    
    @Published var cachedEvents: [EKEvent]?
    private var cancellables = Set<AnyCancellable>()
    deinit { cancellables.forEach { $0.cancel() } }
    
    init(store: EKEventStore, predicate: NSPredicate, refresh: TimeInterval, transform: @escaping ([EKEvent]) -> [EKEvent]) {
        self.store = store
        self.predicate = predicate
        self.transform = transform
        // On initialization (first launch), refresh the event cache
        self.refreshEventCache()
        
        // Every time the calendar changes, refresh the event cache
        NotificationCenter.default
            .publisher(for: .EKEventStoreChanged, object: self.store)
            .assertNoFailure()
            .sink { [weak self] _ in
                if let self = self { self.refreshEventCache() }
            }
            .store(in: &cancellables)
        
        // Refresh the event cache every amount of time specified in `refresh`
        Timer.publish(every: refresh, on: RunLoop.main, in: .common)
            .sink { [weak self] _ in
                if let self = self { self.refreshEventCache() }
            }
            .store(in: &cancellables)
    }
    
    private func fetchEvents() -> [EKEvent] {
        transform(store.events(matching: predicate))
            .compactMap { $0 }
            .sorted()
    }
    
    func refreshEventCache() { cachedEvents = fetchEvents() }
}

extension EKEvent: Comparable {
    public static func < (lhs: EKEvent, rhs: EKEvent) -> Bool {
        lhs.startDate < rhs.startDate
    }
}
