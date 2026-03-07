import SwiftUI

struct TCFlexibleSegmentOption<Value: Hashable>: Identifiable {
    let id: String
    let value: Value
    let title: String

    init(id: String, value: Value, title: String) {
        self.id = id
        self.value = value
        self.title = title
    }
}

struct TCFlexibleSegmentedControl<Value: Hashable>: View {
    let options: [TCFlexibleSegmentOption<Value>]
    @Binding var selection: Value

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(options) { option in
                    let isSelected = selection == option.value
                    Button {
                        selection = option.value
                    } label: {
                        Text(option.title)
                            .font(AppFont.footnote)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .allowsTightening(true)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(isSelected ? Color.white : Color.tcTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minHeight: 34)
                            .background(isSelected ? Color.tcOcean : Color.tcSurface)
                            .overlay {
                                Capsule()
                                    .stroke(isSelected ? Color.tcOcean : Color.tcBorder, lineWidth: 1)
                            }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(4)
        }
        .background(Color.tcSurface)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.tcBorder, lineWidth: 1)
        }
    }
}
