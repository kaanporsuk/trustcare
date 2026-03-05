import SwiftUI

struct PriceLevelView: View {
    let level: Double

    private var roundedLevel: Int {
        min(4, max(0, Int(level.rounded())))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...4, id: \.self) { index in
                Text("$")
                    .font(AppFont.caption)
                    .foregroundStyle(index <= roundedLevel ? Color.tcSage : Color.tcBorder)
            }
        }
    }
}
