import SwiftUI

struct ProviderCardView: View {
    let provider: Provider
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        TCProviderCard(provider: provider, localizedSpecialty: localizedProviderSpecialty) {
            ProviderDetailView(providerId: provider.id)
        }
    }

    private var localizedProviderSpecialty: String {
        guard let specialty = SpecialtyService.shared.specialties.first(where: {
            [
                $0.name,
                $0.nameTr,
                $0.nameDe,
                $0.namePl,
                $0.nameNl,
                $0.nameDa,
            ]
            .compactMap { $0 }
            .contains { $0.caseInsensitiveCompare(provider.specialty) == .orderedSame }
        }) else {
            return provider.specialty
        }

        return specialty.taxonomyDisplayName(using: localizationManager)
    }
}
