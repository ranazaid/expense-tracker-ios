import SwiftUI

/// Fixed set of spending categories. Each category owns a stable SF Symbol and
/// color so charts and lists stay consistent no matter how data is filtered.
enum ExpenseCategory: String, CaseIterable, Identifiable {
    case food
    case transport
    case utilities
    case rent
    case shopping
    case health
    case education
    case entertainment
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: return "Food & Dining"
        case .transport: return "Transport"
        case .utilities: return "Utilities"
        case .rent: return "Rent"
        case .shopping: return "Shopping"
        case .health: return "Health"
        case .education: return "Education"
        case .entertainment: return "Entertainment"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .utilities: return "bolt.fill"
        case .rent: return "house.fill"
        case .shopping: return "bag.fill"
        case .health: return "cross.case.fill"
        case .education: return "book.fill"
        case .entertainment: return "film.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .utilities: return .yellow
        case .rent: return .brown
        case .shopping: return .pink
        case .health: return .red
        case .education: return .indigo
        case .entertainment: return .purple
        case .other: return .gray
        }
    }
}
