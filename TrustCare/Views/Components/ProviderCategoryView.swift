import SwiftUI

struct DynamicProviderAvatarView: View {
    let provider: Provider
    let size: CGFloat = 64

    var body: some View {
        if let urlString = provider.photoUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    categoryPlaceholder
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    categoryPlaceholder
                @unknown default:
                    categoryPlaceholder
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            categoryPlaceholder
        }
    }

    private var categoryPlaceholder: some View {
        ZStack {
            Circle().fill(categoryColor)
            Image(systemName: categoryIcon)
                .resizable()
                .scaledToFit()
                .padding(14)
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private var categoryIcon: String {
        let surveyType = SpecialtyService.shared.surveyType(for: provider.specialty)
        return ProviderMapColor.icon(for: surveyType)
    }

    private var categoryColor: Color {
        let surveyType = SpecialtyService.shared.surveyType(for: provider.specialty)
        return ProviderMapColor.color(for: surveyType)
    }
}

#Preview {
    Text("DynamicProviderAvatarView Preview")
        .padding()
}
