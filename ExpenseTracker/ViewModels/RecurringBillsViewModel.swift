import Combine
import CoreData
import Foundation

@MainActor
final class RecurringBillsViewModel: ObservableObject {
    @Published private(set) var bills: [RecurringBill] = []

    private let context: NSManagedObjectContext
    private let engine: RecurringBillEngine
    private var cancellables: Set<AnyCancellable> = []

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        self.engine = RecurringBillEngine(context: context)
        fetch()

        NotificationCenter.default
            .publisher(for: .NSManagedObjectContextDidSave, object: context)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.fetch() }
            .store(in: &cancellables)
    }

    func fetch() {
        bills = (try? context.fetch(RecurringBill.sortedByName())) ?? []
    }

    var monthlyCommitment: Double {
        bills.filter(\.isActive).reduce(0) { $0 + $1.amount }
    }

    func nextDueDate(for bill: RecurringBill) -> Date {
        engine.nextDueDate(for: bill)
    }

    // MARK: - Mutations

    func addBill(name: String, amount: Double, category: ExpenseCategory, dayOfMonth: Int) {
        // New bills start materializing from now — no retroactive instances.
        RecurringBill.create(in: context,
                             name: name,
                             amount: amount,
                             category: category,
                             dayOfMonth: dayOfMonth,
                             lastMaterialized: .now)
        context.saveIfNeeded()
    }

    func toggleActive(_ bill: RecurringBill) {
        bill.isActive.toggle()
        if bill.isActive {
            // Skip the paused stretch instead of back-filling it.
            bill.lastMaterialized = .now
        }
        context.saveIfNeeded()
    }

    func delete(_ bill: RecurringBill) {
        context.delete(bill)
        context.saveIfNeeded()
    }
}
