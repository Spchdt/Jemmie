import Foundation

struct ActiveTimer: Identifiable {
    let id: UUID
    let label: String
    let duration: Int
    let fireDate: Date

    var isExpired: Bool {
        Date.now >= fireDate
    }
}
