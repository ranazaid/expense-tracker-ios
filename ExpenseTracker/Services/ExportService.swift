import CoreData
import Foundation

/// Builds CSV exports of expense data for sharing via `ShareLink`.
enum ExportService {
    /// Plain value snapshot of an expense, safe to hand to the share sheet.
    struct Row {
        let date: Date
        let category: String
        let note: String
        let amount: Double
        let isRecurring: Bool
    }

    static func rows(from expenses: [Expense]) -> [Row] {
        expenses.map {
            Row(date: $0.date,
                category: $0.category.title,
                note: $0.note,
                amount: $0.amount,
                isRecurring: $0.isRecurringInstance)
        }
    }

    static func csv(from rows: [Row]) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        var lines = ["Date,Category,Note,Amount (PKR),Recurring"]
        for row in rows {
            lines.append([
                formatter.string(from: row.date),
                escape(row.category),
                escape(row.note),
                String(format: "%.0f", row.amount),
                row.isRecurring ? "Yes" : "No"
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    /// Writes the CSV to a temporary file and returns its URL.
    static func writeCSV(rows: [Row]) throws -> URL {
        let stamp = Date.now.formatted(.iso8601.year().month().day())
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Expenses-\(stamp).csv")
        try csv(from: rows).data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    /// RFC 4180-style escaping: quote fields containing commas, quotes or newlines.
    private static func escape(_ field: String) -> String {
        guard field.contains(where: { ",\"\n".contains($0) }) else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
