import SwiftUI

struct SpecialtyBrowserSheet: View {
    let onSelect: (TaxonomySuggestion) -> Void
    let onClear: () -> Void

    var body: some View {
        TaxonomyPickerView(
            titleKey: "specialties_title",
            initialEntityType: .specialty,
            onSelect: onSelect,
            onClear: onClear
        )
    }
}
