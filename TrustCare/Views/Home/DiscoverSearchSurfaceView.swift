import SwiftUI

struct DiscoverSearchSurfaceView: View {
    let locationName: String
    let isLocationUnset: Bool
    @Binding var searchText: String
    let taxonomySuggestions: [TaxonomySuggestion]
    let smartPills: [HomeViewModel.SmartPillItem]
    let selectedSmartPillEntityID: String?
    @Binding var viewMode: HomeViewModel.ViewMode
    let onTapLocation: () -> Void
    let onClearSearch: () -> Void
    let onSelectSuggestion: (TaxonomySuggestion) -> Void
    let onSelectSmartPill: (String?) -> Void
    let onTapMore: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.primary.opacity(0.72))

                TextField(
                    "",
                    text: $searchText,
                    prompt: Text("search_placeholder")
                        .foregroundStyle(.secondary)
                )
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

                if !searchText.isEmpty {
                    Button(action: onClearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 50)
            .background(Color(.systemGray6).opacity(0.98))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button(action: onTapLocation) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColor.trustBlue)
                        .frame(width: 30, height: 30)
                        .background(AppColor.trustBlue.opacity(0.12))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        if isLocationUnset {
                            Text("default_city_name")
                                .font(AppFont.headline.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        } else {
                            Text(locationName)
                                .font(AppFont.headline.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        }
                        Text("country_turkey")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: AppSpacing.sm)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 6)
                .background(AppColor.cardBackground.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                        .stroke(Color.white.opacity(0.52), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            }
            .buttonStyle(.plain)

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               !taxonomySuggestions.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("specialties_label")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, AppSpacing.xs)

                    ForEach(taxonomySuggestions.prefix(4)) { suggestion in
                        Button {
                            onSelectSuggestion(suggestion)
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "cross.case")
                                Text(suggestion.label)
                                    .font(AppFont.body)
                                Spacer()
                            }
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColor.cardBackground.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .shadow(color: DesignShadow.color, radius: DesignShadow.radius, x: DesignShadow.x, y: DesignShadow.y)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    discoverPill(titleKey: "filter_all", isSelected: selectedSmartPillEntityID == nil) {
                        onSelectSmartPill(nil)
                    }

                    ForEach(smartPills) { pill in
                        discoverPill(title: pill.label, isSelected: selectedSmartPillEntityID == pill.entityID) {
                            onSelectSmartPill(pill.entityID)
                        }
                    }

                    discoverPill(titleKey: "filter_more", isSelected: false, iconName: "plus") {
                        onTapMore()
                    }
                }
                .padding(.horizontal, 2)
            }

            Picker("", selection: $viewMode) {
                Text("map_toggle_map").tag(HomeViewModel.ViewMode.map)
                Text("map_toggle_list").tag(HomeViewModel.ViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(height: 30)
            .padding(2)
            .background(Color.white.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(0.92)
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.11), radius: 14, y: 5)
    }

    private func discoverPill(
        title: String,
        isSelected: Bool,
        iconName: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(AppFont.caption)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 36)
            .background(isSelected ? AppColor.trustBlue : AppColor.cardBackground.opacity(0.95))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppColor.border.opacity(0.9), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func discoverPill(
        titleKey: LocalizedStringKey,
        isSelected: Bool,
        iconName: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(titleKey)
                    .lineLimit(1)
            }
            .font(AppFont.caption)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 36)
            .background(isSelected ? AppColor.trustBlue : AppColor.cardBackground.opacity(0.95))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppColor.border.opacity(0.9), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
