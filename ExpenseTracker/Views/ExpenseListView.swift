import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

struct ExpenseListView: View {
    @StateObject private var viewModel = ExpenseListViewModel()
    @State private var isAddingExpense = false

    var body: some View {
        NavigationStack {
            List {
                summarySection
                ForEach(viewModel.sections, id: \.day) { section in
                    Section(section.day.formatted(date: .abbreviated, time: .omitted)) {
                        ForEach(section.items) { expense in
                            ExpenseRow(expense: expense)
                        }
                        .onDelete { offsets in
                            offsets.map { section.items[$0] }.forEach(viewModel.delete)
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .searchable(text: $viewModel.searchText, prompt: "Search notes or categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { filterMenu }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    exportLink
                    Button {
                        isAddingExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingExpense) {
                AddExpenseView(viewModel: viewModel)
            }
            .overlay {
                if viewModel.filtered.isEmpty {
                    ContentUnavailableCompatView(
                        title: "No expenses found",
                        symbol: "tray",
                        message: "Try clearing the search or category filter."
                    )
                }
            }
        }
    }

    private var summarySection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.categoryFilter.map { "\($0.title) total" } ?? "Total shown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.filteredTotal.pkr)
                        .font(.title2.weight(.bold))
                        .monospacedDigit()
                }
                Spacer()
                Text("\(viewModel.filtered.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Button("All Categories") { viewModel.categoryFilter = nil }
            Divider()
            ForEach(ExpenseCategory.allCases) { category in
                Button {
                    viewModel.categoryFilter = category
                } label: {
                    Label(category.title, systemImage: category.symbol)
                }
            }
        } label: {
            Image(systemName: viewModel.categoryFilter == nil
                  ? "line.3.horizontal.decrease.circle"
                  : "line.3.horizontal.decrease.circle.fill")
        }
    }

    private var exportLink: some View {
        ShareLink(
            item: CSVExport(rows: viewModel.exportRows()),
            preview: SharePreview("Expenses CSV", image: Image(systemName: "doc.text"))
        ) {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

// MARK: - Row

private struct ExpenseRow: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: expense.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.note.isEmpty ? expense.category.title : expense.note)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(expense.category.title)
                    if expense.isRecurringInstance {
                        Label("Recurring", systemImage: "arrow.triangle.2.circlepath")
                            .labelStyle(.iconOnly)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(expense.amount.pkr)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - CSV transferable

/// Lazily renders the CSV file only when the user actually shares.
struct CSVExport: Transferable {
    let rows: [ExportService.Row]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { export in
            SentTransferredFile(try ExportService.writeCSV(rows: export.rows))
        }
    }
}

// MARK: - Empty state (iOS 16 compatible)

struct ContentUnavailableCompatView: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
}
