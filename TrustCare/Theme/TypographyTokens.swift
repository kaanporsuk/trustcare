import SwiftUI

extension View {
    func tcTitle1() -> some View {
        font(.system(.largeTitle, design: .default).weight(.bold))
    }

    func tcTitle3() -> some View {
        font(.system(.title3, design: .default).weight(.semibold))
    }

    func tcHeadline() -> some View {
        font(.system(.headline, design: .default).weight(.semibold))
    }

    func tcBody() -> some View {
        font(.system(.body, design: .default))
    }

    func tcCaption() -> some View {
        font(.system(.caption, design: .default))
    }
}
