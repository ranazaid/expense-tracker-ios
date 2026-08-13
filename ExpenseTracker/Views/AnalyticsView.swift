import Charts
import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    statRow
                    card("Monthly Spend", subtitle: "Last 6 months") { monthlyChart }
                    card("By Category", subtitle: "This month") { categoryChart }
                    card("Daily Trend", subtitle: "Last 30 days") { trendChart }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
        }
    }

    // MARK: - Stat tiles

    private var statRow: some View {
        HStack(spacing: 12) {
            StatTile(title: "Spent this month",
                     value: viewModel.thisMonthTotal.pkr)
            StatTile(title: "Daily average",
                     value: viewModel.dailyAverage.pkr,
                     caption: "month to date")
        }
    }

    // MARK: - Charts

    private var monthlyChart: some View {
        Chart(viewModel.monthlySpend) { month in
            BarMark(
                x: .value("Month", month.monthStart, unit: .month),
                y: .value("Spent", month.total),
                width: .ratio(0.55)
            )
            .cornerRadius(4)
            .foregroundStyle(Color.accentColor.gradient)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text((amount / 1000).formatted(.number.precision(.fractionLength(0))) + "k")
                    }
                }
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    private var categoryChart: some View {
        let spend = viewModel.categorySpendThisMonth
        let domain = spend.map { $0.category.title }
        let range = spend.map { $0.category.color }

        Group {
            if #available(iOS 17.0, *) {
                Chart(spend) { item in
                    SectorMark(
                        angle: .value("Amount", item.total),
                        innerRadius: .ratio(0.62),
                        angularInset: 1.5
                    )
                    .cornerRadius(3)
                    .foregroundStyle(by: .value("Category", item.category.title))
                }
                .chartBackground { proxy in
                    GeometryReader { geometry in
                        if let frame = proxy.plotFrame.map({ geometry[$0] }) {
                            VStack(spacing: 2) {
                                Text("Total")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(viewModel.thisMonthTotal.pkr)
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }
            } else {
                // iOS 16 fallback: horizontal bars carry the same information.
                Chart(spend) { item in
                    BarMark(
                        x: .value("Amount", item.total),
                        y: .value("Category", item.category.title)
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Category", item.category.title))
                }
                .chartXAxis(.hidden)
            }
        }
        .chartForegroundStyleScale(domain: domain, range: range)
        .chartLegend(position: .bottom, spacing: 12)
        .frame(height: 260)
    }

    private var trendChart: some View {
        Chart(viewModel.dailyTrend) { day in
            LineMark(
                x: .value("Day", day.day, unit: .day),
                y: .value("Spent", day.total)
            )
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .foregroundStyle(Color.accentColor)

            AreaMark(
                x: .value("Day", day.day, unit: .day),
                y: .value("Spent", day.total)
            )
            .interpolationMethod(.monotone)
            .foregroundStyle(
                LinearGradient(colors: [Color.accentColor.opacity(0.25), .clear],
                               startPoint: .top, endPoint: .bottom)
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .frame(height: 180)
    }

    // MARK: - Card container

    private func card(_ title: String, subtitle: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
