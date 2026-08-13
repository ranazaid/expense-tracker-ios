import CoreData

// MARK: - Expense

@objc(Expense)
final class Expense: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var amount: Double
    @NSManaged var categoryRaw: String
    @NSManaged var note: String
    @NSManaged var date: Date
    @NSManaged var isRecurringInstance: Bool
    @NSManaged var billID: UUID?

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    static func sortedByDate() -> NSFetchRequest<Expense> {
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return request
    }

    @discardableResult
    static func create(in context: NSManagedObjectContext,
                       amount: Double,
                       category: ExpenseCategory,
                       note: String,
                       date: Date,
                       isRecurringInstance: Bool = false,
                       billID: UUID? = nil) -> Expense {
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.amount = amount
        expense.category = category
        expense.note = note
        expense.date = date
        expense.isRecurringInstance = isRecurringInstance
        expense.billID = billID
        return expense
    }
}

// MARK: - RecurringBill

@objc(RecurringBill)
final class RecurringBill: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var amount: Double
    @NSManaged var categoryRaw: String
    @NSManaged var dayOfMonth: Int16
    @NSManaged var isActive: Bool
    @NSManaged var lastMaterialized: Date?

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    static func sortedByName() -> NSFetchRequest<RecurringBill> {
        let request = NSFetchRequest<RecurringBill>(entityName: "RecurringBill")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return request
    }

    @discardableResult
    static func create(in context: NSManagedObjectContext,
                       name: String,
                       amount: Double,
                       category: ExpenseCategory,
                       dayOfMonth: Int,
                       lastMaterialized: Date?) -> RecurringBill {
        let bill = RecurringBill(context: context)
        bill.id = UUID()
        bill.name = name
        bill.amount = amount
        bill.category = category
        bill.dayOfMonth = Int16(dayOfMonth)
        bill.isActive = true
        bill.lastMaterialized = lastMaterialized
        return bill
    }
}

// MARK: - Budget

@objc(Budget)
final class Budget: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var categoryRaw: String
    @NSManaged var monthlyLimit: Double

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    static func sortedByCategory() -> NSFetchRequest<Budget> {
        let request = NSFetchRequest<Budget>(entityName: "Budget")
        request.sortDescriptors = [NSSortDescriptor(key: "categoryRaw", ascending: true)]
        return request
    }

    @discardableResult
    static func create(in context: NSManagedObjectContext,
                       category: ExpenseCategory,
                       monthlyLimit: Double) -> Budget {
        let budget = Budget(context: context)
        budget.id = UUID()
        budget.category = category
        budget.monthlyLimit = monthlyLimit
        return budget
    }
}
