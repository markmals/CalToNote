import Foundation

extension DateComponents {
    public var members: Set<Calendar.Component> {
        func validateMember(_ value: Int?) -> Bool {
            guard let value = value, value != Int.max, value != Int.min
                else { return false }
            return true
        }
        
        var components: Set<Calendar.Component> = []
        if validateMember(era) { components.insert(.era) }
        if validateMember(year) { components.insert(.year) }
        if validateMember(month) { components.insert(.month) }
        if validateMember(day) { components.insert(.day) }
        if validateMember(hour) { components.insert(.hour) }
        if validateMember(minute) { components.insert(.minute) }
        if validateMember(second) { components.insert(.second) }
        if validateMember(weekday) { components.insert(.weekday) }
        if validateMember(weekdayOrdinal) { components.insert(.weekdayOrdinal) }
        if validateMember(quarter) { components.insert(.quarter) }
        if validateMember(weekOfMonth) { components.insert(.weekOfMonth) }
        if validateMember(weekOfYear) { components.insert(.weekOfYear) }
        if validateMember(yearForWeekOfYear) { components.insert(.yearForWeekOfYear) }
        if validateMember(nanosecond) { components.insert(.nanosecond) }
        return components
    }
    
    /// Add two date components together
    public static func + (lhs: DateComponents, rhs: DateComponents) -> DateComponents {
        var copy = DateComponents()
        for component in lhs.members.union(rhs.members) {
            var sum = 0
            // Error workaround where instead of returning nil
            // the values return Int.max
            if let value = lhs.value(for: component),
                value != Int.max, value != Int.min
            { sum = sum + value }
            if let value = rhs.value(for: component),
                value != Int.max, value != Int.min
            { sum = sum + value }
            copy.setValue(sum, for: component)
        }
        return copy
    }
    
    /// Subtract date components
    public static func - (lhs: DateComponents, rhs: DateComponents) -> DateComponents {
        var copy = DateComponents()
        for component in lhs.members.union(rhs.members) {
            var result = 0
            // Error workaround where instead of returning nil
            // the values return Int.max
            if let value = lhs.value(for: component),
                value != Int.max, value != Int.min
            { result = result + value }
            if let value = rhs.value(for: component),
                value != Int.max, value != Int.min
            { result = result - value }
            copy.setValue(result, for: component)
        }
        return copy
    }
}
