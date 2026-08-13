import Combine
import CoreData
import Foundation

@MainActor
final class AnalyticsViewModel: ObservableObject {
    struct MonthlySpend: Identifiable {
        let monthStart: Date
        let total: Double
        var id: Date { monthStart }
    }

    struct CategorySpend: Identifiable {
        let category: ExpenseCategory
        let total: Double
        var id: ExpenseCategory { category }
    }

    struct DailySpend: Identifiable {
        let day: Date
        let total: Double
        var id: Date { day }
    }

    @Published private(set) var monthlySpend: [MonthlySpend] = []
    @Published private(set) var categorySpendThisMonth: [CategorySpend] = []
    @Published private(set) var dailyTrend: [DailySpend] = []
    @Published private(set) var thisMonthTotal: Double = 0
    @Published private(set) var dailyAverage: Double = 0

    private let context: NSManagedObjectContext
    private let calendar = Calendar.current
    private var cancellables: Set<AnyCancellable> = []

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        recompute()

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.recompute() }
            .store(in: &cancellables)
    }

    func recompute() {
        let expenses = (try? context.fetch(Expense.sortedByDate())) ?? []
        computeMonthly(expenses)
        computeCategories(expenses)
        computeDailyTrend(expenses)
    }

    // MARK: - Aggregation

    private func computeMonthly(_ expenses: [Expense]) {
        guard let currentMonth = calendar.dateInterval(of: .month, for: .now)?.start else { return }
        let months: [Date] = (0..<6).compactMap {
            calendar.date(byAdding: .month, value: -$0, to: currentMonth)
        }.reversed()

        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.dateInterval(of: .month, for: expense.date)?.start ?? expense.date
        }
        monthlySpend = months.map { month in
            MonthlySpend(monthStart: month,
                         total: (grouped[month] ?? []).reduce(0) { $0 + $1.amount })
        }
        thisMonthTotal = monthlySpend.last?.total ?? 0

        let dayOfMonth = calendar.component(.day, from: .now)
        dailyAverage = dayOfMonth > 0 ? thisMonthTotal / Double(dayOfMonth) : 0
    }

    private func computeCategories(_ expenses: [Expense]) {
        guard let monthStart = calendar.dateInterval(of: .month, for: .now)?.start else { return }
        let thisMonth = expenses.filter { $0.date >= monthStart }
        let totals = thisMonth.reduce(into: [ExpenseCategory: Double]()) {
            $0[$1.category, default: 0] += $1.amount
        }
        // Stable category order keeps colors anchored to categories, not ranks.
        categorySpendThisMonth = ExpenseCategory.allCases.compactMap { category in
            guard let total = totals[category], total > 0 else { return nil }
            return CategorySpend(category: category, total: total)
        }
    }

    private func computeDailyTrend(_ expenses: [Expense]) {
        let today = calendar.startOfDay(for: .now)
        let days: [Date] = (0..<30).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }.reversed()

        let grouped = Dictionary(grouping: expenses) {
            calendar.startOfDay(for: $0.date)
        }
        dailyTrend = days.map { day in
            DailySpend(day: day,
                       total: (grouped[day] ?? []).reduce(0) { $0 + $1.amount })
        }
    }
}
