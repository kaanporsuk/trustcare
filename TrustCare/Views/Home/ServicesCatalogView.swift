import SwiftUI

struct ServicesCatalogView: View {
    let providerName: String
    let services: [ProviderServiceItem]
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    private var groupedServices: [(String, [ProviderServiceItem])] {
        let grouped = Dictionary(grouping: services, by: { $0.category ?? String(localized: "Other") })
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text(String(localized: "Services & Prices"))
                    .font(AppFont.title2)

                if isLoading && services.isEmpty {
                    VStack {
                        ProgressView()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                } else if services.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "stethoscope")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text(String(localized: "No services yet"))
                            .font(AppFont.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                } else {
                    ForEach(groupedServices, id: \.0) { category, items in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(category)
                                .font(AppFont.headline)

                            ForEach(items) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(AppFont.body)
                                    if let description = item.description {
                                        Text(description)
                                            .font(AppFont.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    HStack(spacing: AppSpacing.sm) {
                                        if let priceMin = item.priceMin {
                                            if let priceMax = item.priceMax {
                                                Text("\(item.currency)\(String(format: "%.0f", priceMin)) - \(item.currency)\(String(format: "%.0f", priceMax))")
                                            } else {
                                                Text("\(item.currency)\(String(format: "%.0f", priceMin))")
                                            }
                                        }
                                        if let duration = item.durationMinutes {
                                            Text("\(duration) min")
                                                .font(AppFont.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .font(AppFont.body)
                                    .foregroundStyle(AppColor.trustBlue)
                                }
                                .padding(.vertical, AppSpacing.xs)
                            }
                        }
                    }
                }

                Button {
                } label: {
                    Label(String(localized: "Contact for Booking"), systemImage: "phone")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppColor.trustBlue)
                        .foregroundStyle(.white)
                        .cornerRadius(AppRadius.button)
                }
            }
            .padding(AppSpacing.lg)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(providerName)
        .onAppear {
            isLoading = false
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "OK")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
