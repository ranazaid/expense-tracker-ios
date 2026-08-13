import SwiftUI

struct BudgetsView: View {
    @StateObject private var viewModel = BudgetsViewModel()
    @State private var isAddingBudget = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.statuses) { status in
                        BudgetRow(status: status)
                    }
                    .onDelete { offsets in
                        offsets.map { viewModel.statuses[$0] }.forEach(viewModel.delete)
                    }
                } header: {
                    Text("This month")
                } footer: {
                    Text("Budgets reset on the 1st of every month.")
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                Button {
                    isAddingBudget = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(viewModel.categoriesWithoutBudget.isEmpty)
            }
            .sheet(isPresented: $isAddingBudget) {
                AddBudgetView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Row

private struct BudgetRow: View {
    let status: BudgetsViewModel.BudgetStatus

    private var barColor: Color {
        if status.isOver { return .red }
        if status.isNearLimit { return .orange }
        return status.budget.category.color
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                CategoryIcon(category: status.budget.category)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.budget.category.title)
                        .font(.subheadline.weight(.medium))
                    Text("\(status.spent.pkr) of \(status.limit.pkr)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                statusLabel
            }
            ProgressView(value: status.fraction)
                .tint(barColor)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusLabel: some View {
        if status.isOver {
            Label("Over by \((-status.remaining).pkr)", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
        } else {
            Text("\(status.remaining.pkr) left")
                .font(.caption)
                .foregroundStyle(status.isNearLimit ? .orange : .secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Add budget

private struct AddBudgetView: View {
    @ObservedObject var viewModel: BudgetsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var category: ExpenseCategory?
    @State private var limitText = ""

    private var limit: Double? {
        Double(limitText.replacingOccurrences(of: ",", with: ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Category", selection: $category) {
                    Text("Select…").tag(ExpenseCategory?.none)
                    ForEach(viewModel.categoriesWithoutBudget) { category in
                        Label(category.title, systemImage: category.symbol)
                            .tag(ExpenseCategory?.some(category))
                    }
                }
                HStack {
                    Text("Monthly limit")
                    Spacer()
                    Text("Rs")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $limitText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }
            .navigationTitle("New Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let category, let limit {
                            viewModel.addBudget(category: category, limit: limit)
                        }
                        dismiss()
                    }
                    .disabled(category == nil || (limit ?? 0) <= 0)
                }
            }
        }
    }
}
