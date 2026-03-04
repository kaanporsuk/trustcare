import SwiftUI

struct MapLegendView: View {
    @ObservedObject var viewModel: HomeViewModel

    private let categories: [(type: String, labelKey: String)] = [
        ("general_clinic", "legend_clinic"),
        ("pharmacy",       "legend_pharmacy"),
        ("hospital",       "legend_hospital"),
        ("dental",         "legend_dental"),
        ("aesthetics",     "legend_aesthetics"),
        ("diagnostic",     "legend_lab"),
        ("mental_health",  "legend_mental_health"),
        ("rehabilitation", "legend_rehab"),
    ]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Toggle button (always visible)
            Button {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(
                            viewModel.selectedSurveyType.map { ProviderMapColor.color(for: $0) }
                            ?? Color.primary
                        )
                    if !isExpanded {
                        Text(selectedLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.86)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            }
            .buttonStyle(.plain)

            // Expandable legend items
            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    // "Show All" option
                    Button {
                        Task { await viewModel.applyLegendFilter(nil) }
                        withAnimation(.spring(response: 0.3)) { isExpanded = false }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.primary.opacity(0.3))
                                .frame(width: 12, height: 12)
                            Text("show_all")
                                .font(.system(size: 12, weight: viewModel.selectedSurveyType == nil ? .bold : .regular))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(viewModel.selectedSurveyType == nil ? Color.primary.opacity(0.08) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    // Category items
                    ForEach(categories, id: \.type) { cat in
                        Button {
                            let newType = viewModel.selectedSurveyType == cat.type ? nil : cat.type
                            Task { await viewModel.applyLegendFilter(newType) }
                            if newType != nil {
                                withAnimation(.spring(response: 0.3)) { isExpanded = false }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(ProviderMapColor.color(for: cat.type))
                                    .frame(width: 12, height: 12)
                                Text(LocalizedStringKey(cat.labelKey))
                                    .font(.system(size: 12, weight: viewModel.selectedSurveyType == cat.type ? .bold : .regular))
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(
                                viewModel.selectedSurveyType == cat.type
                                ? ProviderMapColor.color(for: cat.type).opacity(0.12)
                                : Color.clear
                            )
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
            }
        }
    }

    /// Label shown on the collapsed capsule
    private var selectedLabel: LocalizedStringKey {
        guard let type = viewModel.selectedSurveyType else {
            return LocalizedStringKey("filter_button")
        }
        if let cat = categories.first(where: { $0.type == type }) {
            return LocalizedStringKey(cat.labelKey)
        }
        return LocalizedStringKey("filter_button")
    }
}
