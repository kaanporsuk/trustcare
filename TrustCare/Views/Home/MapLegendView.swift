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
                Label("filter_button", systemImage: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
#if DEBUG
                .overlay(Capsule().stroke(Color.red.opacity(0.25), lineWidth: 1))
#endif
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
}
