import Combine
import CoreData
import SwiftUI

@MainActor
final class ExpenseListViewModel: ObservableObject {
    @Published private(set) var expenses: [Expense] = []
    @Published var searchText = ""
    @Published var categoryFilter: ExpenseCategory?

    private let context: NSManagedObjectContext
    private var cancellables: Set<AnyCancellable> = []

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        fetch()

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.fetch() }
            .store(in: &cancellables)
    }

    func fetch() {
        expenses = (try? context.fetch(Expense.sortedByDate())) ?? []
    }

    // MARK: - Filtering

    var filtered: [Expense] {
        expenses.filter { expense in
            if let categoryFilter, expense.category != categoryFilter { return false }
            guard !searchText.isEmpty else { return true }
            return expense.note.localizedCaseInsensitiveContains(searchText)
                || expense.category.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Filtered expenses grouped by day, newest first, for sectioned display.
    var sections: [(day: Date, items: [Expense])] {
        let groups = Dictionary(grouping: filtered) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return groups.keys.sorted(by: >).map { (day: $0, items: groups[$0] ?? []) }
    }

    var filteredTotal: Double {
        filtered.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Mutations

    func addExpense(amount: Double, category: ExpenseCategory, note: String, date: Date) {
        Expense.create(in: context, amount: amount, category: category, note: note, date: date)
        context.saveIfNeeded()
    }

    func delete(_ expense: Expense) {
        context.delete(expense)
        context.saveIfNeeded()
    }

    // MARK: - Export

    func exportRows() -> [ExportService.Row] {
        ExportService.rows(from: filtered)
    }
}
