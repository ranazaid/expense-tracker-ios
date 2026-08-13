import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var viewModel: ExpenseListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var note = ""
    @State private var date: Date = .now
    @FocusState private var amountFocused: Bool

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }

    private var canSave: Bool {
        (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("Rs")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                            .focused($amountFocused)
                    }
                }

                Section("Category") {
                    CategoryPicker(selection: $category)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section("Details") {
                    TextField("Note (e.g. Groceries at Imtiaz)", text: $note)
                    DatePicker("Date", selection: $date, in: ...Date.now,
                               displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear { amountFocused = true }
        }
    }

    private func save() {
        guard let amount else { return }
        viewModel.addExpense(amount: amount, category: category, note: note, date: date)
        dismiss()
    }
}
