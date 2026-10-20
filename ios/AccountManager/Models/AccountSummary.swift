import Foundation

struct AccountSummary: Decodable, Hashable {
    let name: String
    let email: String
    let balanceDue: Double
    /// ISO-8601 calendar date from the API, e.g. "2026-11-01".
    let dueDate: String
    let lines: [Line]

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var formattedDueDate: String {
        let parser = DateFormatter()
        parser.calendar = Calendar(identifier: .iso8601)
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dueDate) else { return dueDate }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

struct Line: Decodable, Hashable, Identifiable {
    let name: String
    let phoneNumber: String
    let plan: String
    let dataUsedGb: Double
    let dataLimitGb: Double

    var id: String { phoneNumber }
}
