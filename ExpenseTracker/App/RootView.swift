import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "list.bullet.rectangle") }

            BudgetsView()
                .tabItem { Label("Budgets", systemImage: "chart.bar.doc.horizontal") }

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.pie") }

            RecurringBillsView()
                .tabItem { Label("Bills", systemImage: "arrow.triangle.2.circlepath") }
        }
    }
}
