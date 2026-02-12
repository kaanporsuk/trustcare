import SwiftUI

struct ReviewListView: View {
    let providerId: UUID
    @State private var reviews: [Review] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && reviews.isEmpty {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if reviews.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "text.bubble")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "No reviews yet"))
                        .font(AppFont.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, AppSpacing.xxl)
            } else {
                List {
                    ForEach(reviews) { review in
                        ReviewItemView(review: review)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await loadReviews()
                }
            }
        }
        .navigationTitle(String(localized: "Reviews"))
        .task {
            await loadReviews()
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadReviews() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            reviews = try await ProviderService.fetchReviewsForProvider(providerId, limit: 50, offset: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
