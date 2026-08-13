import SwiftUI

@main
struct ExpenseTrackerApp: App {
    private let persistence = PersistenceController.shared

    init() {
        let context = persistence.container.viewContext
        MockDataService.seedIfNeeded(in: context)
        // Materialize any recurring bill instances that came due since last launch.
        RecurringBillEngine(context: context).materializeDueBills()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
