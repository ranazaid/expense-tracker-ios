import CoreData

/// Core Data stack built around a programmatic model — no .xcdatamodeld file,
/// which keeps schema changes reviewable in plain Swift.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ExpenseTracker", managedObjectModel: Self.model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Model

    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let expense = NSEntityDescription()
        expense.name = "Expense"
        expense.managedObjectClassName = NSStringFromClass(Expense.self)
        expense.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("amount", .doubleAttributeType, defaultValue: 0),
            attribute("categoryRaw", .stringAttributeType, defaultValue: ExpenseCategory.other.rawValue),
            attribute("note", .stringAttributeType, defaultValue: ""),
            attribute("date", .dateAttributeType),
            attribute("isRecurringInstance", .booleanAttributeType, defaultValue: false),
            attribute("billID", .UUIDAttributeType, optional: true)
        ]

        let bill = NSEntityDescription()
        bill.name = "RecurringBill"
        bill.managedObjectClassName = NSStringFromClass(RecurringBill.self)
        bill.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType, defaultValue: ""),
            attribute("amount", .doubleAttributeType, defaultValue: 0),
            attribute("categoryRaw", .stringAttributeType, defaultValue: ExpenseCategory.other.rawValue),
            attribute("dayOfMonth", .integer16AttributeType, defaultValue: 1),
            attribute("isActive", .booleanAttributeType, defaultValue: true),
            attribute("lastMaterialized", .dateAttributeType, optional: true)
        ]

        let budget = NSEntityDescription()
        budget.name = "Budget"
        budget.managedObjectClassName = NSStringFromClass(Budget.self)
        budget.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("categoryRaw", .stringAttributeType, defaultValue: ExpenseCategory.other.rawValue),
            attribute("monthlyLimit", .doubleAttributeType, defaultValue: 0)
        ]

        model.entities = [expense, bill, budget]
        return model
    }()

    private static func attribute(_ name: String,
                                  _ type: NSAttributeType,
                                  optional: Bool = false,
                                  defaultValue: Any? = nil) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }
}

extension NSManagedObjectContext {
    /// Saves only when there is something to save; keeps call sites tidy.
    func saveIfNeeded() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            assertionFailure("Core Data save failed: \(error)")
            rollback()
        }
    }
}
