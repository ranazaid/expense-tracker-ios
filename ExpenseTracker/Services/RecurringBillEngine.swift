import CoreData
import Foundation

/// Turns recurring bill definitions into concrete `Expense` rows.
///
/// On every launch the engine walks each active bill from its
/// `lastMaterialized` marker and creates one expense per due date that has
/// passed since, so bills keep flowing in even if the app was closed for
/// months. Months shorter than the bill's day (e.g. day 31 in February) clamp
/// to the last day of that month.
struct RecurringBillEngine {
    let context: NSManagedObjectContext
    var calendar: Calendar = .current

    @discardableResult
    func materializeDueBills(asOf now: Date = .now) -> Int {
        let bills = (try? context.fetch(RecurringBill.sortedByName())) ?? []
        var created = 0

        for bill in bills where bill.isActive {
            let anchor = bill.lastMaterialized ?? now
            var nextDue = dueDate(after: anchor, dayOfMonth: Int(bill.dayOfMonth))

            while nextDue <= now {
                Expense.create(in: context,
                               amount: bill.amount,
                               category: bill.category,
                               note: bill.name,
                               date: nextDue,
                               isRecurringInstance: true,
                               billID: bill.id)
                bill.lastMaterialized = nextDue
                created += 1
                nextDue = dueDate(after: nextDue, dayOfMonth: Int(bill.dayOfMonth))
            }
        }

        context.saveIfNeeded()
        return created
    }

    /// First occurrence of `dayOfMonth` strictly after `date`.
    func dueDate(after date: Date, dayOfMonth: Int) -> Date {
        var components = calendar.dateComponents([.year, .month], from: date)
        for _ in 0..<24 { // hard bound; two years is more than any catch-up needs
            let candidate = clampedDate(year: components.year!, month: components.month!, day: dayOfMonth)
            if candidate > date { return candidate }
            components.month! += 1
            if components.month! > 12 {
                components.month = 1
                components.year! += 1
            }
        }
        return calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// Next due date for display ("Next: 1 Sep").
    func nextDueDate(for bill: RecurringBill, asOf now: Date = .now) -> Date {
        dueDate(after: max(bill.lastMaterialized ?? now, now), dayOfMonth: Int(bill.dayOfMonth))
    }

    private func clampedDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents(year: year, month: month, day: 1, hour: 9)
        let firstOfMonth = calendar.date(from: components)!
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)!.count
        components.day = min(day, daysInMonth)
        return calendar.date(from: components)!
    }
}
