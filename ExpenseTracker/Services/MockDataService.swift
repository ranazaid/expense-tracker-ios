import CoreData
import Foundation

/// Seeds the store with believable local demo data on first launch so the app
/// is fully usable offline with zero configuration.
enum MockDataService {
    static func seedIfNeeded(in context: NSManagedObjectContext) {
        let count = (try? context.count(for: Expense.sortedByDate())) ?? 0
        guard count == 0 else { return }

        seedExpenses(in: context)
        seedRecurringBills(in: context)
        seedBudgets(in: context)
        context.saveIfNeeded()
    }

    // MARK: - Expenses

    private static func seedExpenses(in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var rng = SeededGenerator(seed: 42)

        // (note, category, base amount, spread) — everyday spending in PKR.
        let templates: [(String, ExpenseCategory, Double, Double)] = [
            ("Groceries at Imtiaz", .food, 3200, 1400),
            ("Chai and samosa", .food, 250, 120),
            ("Foodpanda dinner", .food, 1150, 450),
            ("Biryani lunch", .food, 480, 180),
            ("Careem to office", .transport, 520, 220),
            ("Petrol at PSO", .transport, 2500, 900),
            ("Rickshaw fare", .transport, 300, 150),
            ("Mobile top-up (Jazz)", .utilities, 500, 200),
            ("SSGC gas bill", .utilities, 1850, 600),
            ("Daraz order", .shopping, 2400, 1600),
            ("Khaadi kurta", .shopping, 3800, 1200),
            ("Medicine from Sehat", .health, 850, 400),
            ("Doctor consultation", .health, 2000, 500),
            ("Course book", .education, 1500, 700),
            ("Cinema tickets", .entertainment, 1600, 500),
            ("Cricket match snacks", .entertainment, 700, 250)
        ]

        // Spread ~70 expenses over the last ~95 days, 0–2 per day.
        for daysAgo in 0..<95 {
            let perDay = rng.next(upTo: 3)
            for _ in 0..<perDay {
                let template = templates[rng.next(upTo: templates.count)]
                let jitter = Double(rng.next(upTo: 200)) / 100.0 - 1.0 // -1...1
                let amount = (template.2 + template.3 * jitter).rounded(toNearest: 10)
                var date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
                date = calendar.date(byAdding: .hour, value: 9 + rng.next(upTo: 12), to: date)!
                Expense.create(in: context,
                               amount: max(amount, 50),
                               category: template.1,
                               note: template.0,
                               date: date)
            }
        }
    }

    // MARK: - Recurring bills

    private static func seedRecurringBills(in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        // Anchor two months back so the engine visibly materializes instances
        // on first launch.
        let anchor = calendar.date(byAdding: .month, value: -2, to: .now)!

        RecurringBill.create(in: context, name: "House rent", amount: 45000,
                             category: .rent, dayOfMonth: 1, lastMaterialized: anchor)
        RecurringBill.create(in: context, name: "K-Electric bill", amount: 8500,
                             category: .utilities, dayOfMonth: 7, lastMaterialized: anchor)
        RecurringBill.create(in: context, name: "PTCL internet", amount: 3499,
                             category: .utilities, dayOfMonth: 12, lastMaterialized: anchor)
        RecurringBill.create(in: context, name: "Netflix", amount: 1100,
                             category: .entertainment, dayOfMonth: 20, lastMaterialized: anchor)
    }

    // MARK: - Budgets

    private static func seedBudgets(in context: NSManagedObjectContext) {
        Budget.create(in: context, category: .food, monthlyLimit: 25000)
        Budget.create(in: context, category: .transport, monthlyLimit: 12000)
        Budget.create(in: context, category: .utilities, monthlyLimit: 16000)
        Budget.create(in: context, category: .shopping, monthlyLimit: 10000)
        Budget.create(in: context, category: .entertainment, monthlyLimit: 6000)
    }
}

// MARK: - Deterministic random

/// Small linear congruential generator so seed data is identical on every
/// fresh install — keeps screenshots and demos reproducible.
struct SeededGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func next(upTo bound: Int) -> Int {
        Int(next() >> 33) % max(bound, 1)
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double {
        (self / step).rounded() * step
    }
}
