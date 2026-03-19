import Foundation

extension Date {
    /// Start of the current week (Monday)
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Short day name (e.g., "Mon", "Tue")
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Check if date is within last N days
    func isWithinLast(days: Int) -> Bool {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return self >= cutoff
    }
}
