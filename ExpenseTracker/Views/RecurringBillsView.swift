import SwiftUI

struct RecurringBillsView: View {
    @StateObject private var viewModel = RecurringBillsViewModel()
    @State private var isAddingBill = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Active bills per month")
                        Spacer()
                        Text(viewModel.monthlyCommitment.pkr)
                            .font(.headline)
                            .monospacedDigit()
                    }
                }

                Section {
                    ForEach(viewModel.bills) { bill in
                        BillRow(bill: bill, nextDue: viewModel.nextDueDate(for: bill)) {
                            viewModel.toggleActive(bill)
                        }
                    }
                    .onDelete { offsets in
                        offsets.map { viewModel.bills[$0] }.forEach(viewModel.delete)
                    }
                } footer: {
                    Text("Due bills are added to your expenses automatically when the app launches.")
                }
            }
            .navigationTitle("Recurring Bills")
            .toolbar {
                Button {
                    isAddingBill = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $isAddingBill) {
                AddBillView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Row

private struct BillRow: View {
    let bill: RecurringBill
    let nextDue: Date
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: bill.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(bill.name)
                    .font(.subheadline.weight(.medium))
                Text(bill.isActive
                     ? "Next: \(nextDue.formatted(date: .abbreviated, time: .omitted))"
                     : "Paused")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(bill.amount.pkr)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text("day \(bill.dayOfMonth)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Toggle("", isOn: Binding(get: { bill.isActive }, set: { _ in onToggle() }))
                .labelsHidden()
        }
        .opacity(bill.isActive ? 1 : 0.55)
    }
}

// MARK: - Add bill

private struct AddBillView: View {
    @ObservedObject var viewModel: RecurringBillsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .utilities
    @State private var dayOfMonth = 1

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name (e.g. K-Electric bill)", text: $name)
                HStack {
                    Text("Amount")
                    Spacer()
                    Text("Rs")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amountText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { category in
                        Label(category.title, systemImage: category.symbol)
                            .tag(category)
                    }
                }
                Picker("Due day of month", selection: $dayOfMonth) {
                    ForEach(1...28, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
            }
            .navigationTitle("New Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let amount {
                            viewModel.addBill(name: name, amount: amount,
                                              category: category, dayOfMonth: dayOfMonth)
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty || (amount ?? 0) <= 0)
                }
            }
        }
    }
}
