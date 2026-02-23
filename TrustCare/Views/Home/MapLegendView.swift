import SwiftUI

struct MapLegendView: View {
    @ObservedObject var viewModel: HomeViewModel

    let categories: [(type: String, label: String)] = [
        ("general_clinic", "Clinic"),
        ("pharmacy", "Pharmacy"),
        ("hospital", "Hospital"),
        ("dental", "Dental"),
        ("aesthetics", "Aesthetics"),
        ("diagnostic", "Lab"),
        ("mental_health", "Mental Health"),
        ("rehabilitation", "Rehab")
    ]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                        Text(
                            viewModel.selectedSurveyType.map { ProviderMapColor.label(for: $0) }
                            ?? "Filter"
                        )
                        .font(.system(size: 13, weight: .semibold))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        viewModel.selectedSurveyType = nil
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.primary.opacity(0.3))
                                .frame(width: 12, height: 12)
                            Text(String(localized: "show_all"))
                                .font(.system(size: 12, weight: viewModel.selectedSurveyType == nil ? .bold : .regular))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(viewModel.selectedSurveyType == nil ? Color.primary.opacity(0.08) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    ForEach(categories, id: \.type) { cat in
                        Button {
                            if viewModel.selectedSurveyType == cat.type {
                                viewModel.selectedSurveyType = nil
                            } else {
                                viewModel.selectedSurveyType = cat.type
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(ProviderMapColor.color(for: cat.type))
                                    .frame(width: 12, height: 12)
                                Text(cat.label)
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
                .cornerRadius(10)
                .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .topLeading)))
            }
        }
    }
}
