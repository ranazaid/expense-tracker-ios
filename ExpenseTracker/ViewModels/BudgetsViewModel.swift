import Combine
import CoreData
import SwiftUI

@MainActor
final class BudgetsViewModel: ObservableObject {
    struct BudgetStatus: Identifiable {
        let budget: Budget
        let spent: Double

        var id: NSManagedObjectID { budget.objectID }
        var limit: Double { budget.monthlyLimit }
        var fraction: Double { limit > 0 ? min(spent / limit, 1) : 0 }
        var isOver: Bool { spent > limit }
        var isNearLimit: Bool { !isOver && limit > 0 && spent / limit >= 0.8 }
        var remaining: Double { limit - spent }
    }

    @Published private(set) var statuses: [BudgetStatus] = []

    private let context: NSManagedObjectContext
    private var cancellables: Set<AnyCancellable> = []

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        refresh()

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    func refresh() {
        let budgets = (try? context.fetch(Budget.sortedByCategory())) ?? []
        let monthSpend = spendByCategoryThisMonth()
        statuses = budgets.map {
            BudgetStatus(budget: $0, spent: monthSpend[$0.category] ?? 0)
        }
    }

    var categoriesWithoutBudget: [ExpenseCategory] {
        let used = Set(statuses.map { $0.budget.category })
        return ExpenseCategory.allCases.filter { !used.contains($0) }
    }

    func addBudget(category: ExpenseCategory, limit: Double) {
        Budget.create(in: context, category: category, monthlyLimit: limit)
        context.saveIfNeeded()
    }

    func updateLimit(for status: BudgetStatus, to limit: Double) {
        status.budget.monthlyLimit = limit
        context.saveIfNeeded()
    }

    func delete(_ status: BudgetStatus) {
        context.delete(status.budget)
        context.saveIfNeeded()
    }

    // MARK: - Helpers

    private func spendByCategoryThisMonth() -> [ExpenseCategory: Double] {
        let calendar = Calendar.current
        guard let monthStart = calendar.dateInterval(of: .month, for: .now)?.start else { return [:] }

        let request = Expense.sortedByDate()
        request.predicate = NSPredicate(format: "date >= %@", monthStart as NSDate)
        let expenses = (try? context.fetch(request)) ?? []

        return expenses.reduce(into: [:]) { result, expense in
            result[expense.category, default: 0] += expense.amount
        }
    }
}
