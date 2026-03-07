import SwiftUI

struct LocalizationFitPreviewView: View {
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var reviewFilter: String = "all"
    @State private var targetMode: ReviewSubmissionViewModel.TargetMode = .both
    @State private var visitType: String = ReviewVisitType.all.first?.id ?? "examination"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("UI Fit Preview")
                    .font(AppFont.title2)
                    .padding(.top, AppSpacing.md)

                section("My Reviews Segmented") {
                    TCFlexibleSegmentedControl(
                        options: [
                            TCFlexibleSegmentOption(id: "all", value: "all", title: tcString("filter_all", fallback: "All")),
                            TCFlexibleSegmentOption(id: "verified", value: "verified", title: tcString("status_verified", fallback: "Verified")),
                            TCFlexibleSegmentOption(id: "pending", value: "pending", title: tcString("status_pending", fallback: "Pending")),
                            TCFlexibleSegmentOption(id: "unverified", value: "unverified", title: tcString("status_unverified", fallback: "Unverified")),
                        ],
                        selection: $reviewFilter
                    )
                }

                section("ReviewHub Segmented") {
                    VStack(spacing: AppSpacing.sm) {
                        TCFlexibleSegmentedControl(
                            options: [
                                TCFlexibleSegmentOption(id: "provider", value: .provider, title: tcString("claim_provider_label", fallback: "Provider")),
                                TCFlexibleSegmentOption(id: "facility", value: .facility, title: tcString("chip_facility", fallback: "Facility")),
                                TCFlexibleSegmentOption(
                                    id: "both",
                                    value: .both,
                                    title: "\(tcString("claim_provider_label", fallback: "Provider")) + \(tcString("chip_facility", fallback: "Facility"))"
                                ),
                            ],
                            selection: $targetMode
                        )

                        TCFlexibleSegmentedControl(
                            options: ReviewVisitType.all.map {
                                TCFlexibleSegmentOption(id: $0.id, value: $0.id, title: $0.label(for: localizationManager.effectiveLanguage))
                            },
                            selection: $visitType
                        )
                    }
                }

                section("Empty State + CTA") {
                    TCEmptyState(
                        variant: .noReviews,
                        customTitle: tcString("my_reviews_empty_title", fallback: "No reviews yet"),
                        customBody: tcString("my_reviews_empty_message", fallback: "Share your experience by posting your first review."),
                        primaryTitle: tcString("my_reviews_empty_action", fallback: "Write a Review"),
                        secondaryTitle: tcString("button_cancel", fallback: "Cancel")
                    ) {
                        // No-op for preview.
                    } onSecondary: {
                        // No-op for preview.
                    }
                }

                section("Filter Chips") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            TCFilterChip(title: tcString("chip_specialty", fallback: "Specialty"), isSelected: true) {}
                            TCFilterChip(title: tcString("chip_treatment", fallback: "Treatment"), isSelected: false) {}
                            TCFilterChip(title: tcString("chip_facility", fallback: "Facility"), isSelected: false) {}
                            TCFilterChip(title: tcString("chip_distance", fallback: "Distance"), isSelected: false) {}
                            TCFilterChip(title: tcString("chip_language", fallback: "Language"), isSelected: false) {}
                            TCFilterChip(title: tcString("filter_verified", fallback: "Verified"), isSelected: false) {}
                        }
                    }
                }

                section("Primary CTA") {
                    TCPrimaryButton(title: tcString("my_reviews_empty_action", fallback: "Write a Review"), fullWidth: true) {}
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .navigationTitle(Text(verbatim: "UI Fit Preview"))
    }

    @ViewBuilder
    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.headline)
            content()
        }
    }
}
