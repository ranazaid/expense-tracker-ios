import SwiftUI

// MARK: - Currency formatting

extension Double {
    /// "Rs 45,000" — whole-rupee display used across the app.
    var pkr: String {
        "Rs " + (Self.grouping.string(from: NSNumber(value: self.rounded())) ?? "0")
    }

    private static let grouping: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter
    }()
}

// MARK: - Category icon

struct CategoryIcon: View {
    let category: ExpenseCategory
    var size: CGFloat = 36

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color.gradient, in: RoundedRectangle(cornerRadius: size * 0.28))
    }
}

// MARK: - Category chip picker

struct CategoryPicker: View {
    @Binding var selection: ExpenseCategory

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ExpenseCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 6) {
                        CategoryIcon(category: category, size: 34)
                        Text(category.title)
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selection == category
                                  ? category.color.opacity(0.15)
                                  : Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selection == category ? category.color : .clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let title: String
    let value: String
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}
