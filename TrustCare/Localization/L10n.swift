import Foundation
import SwiftUI

enum L10n {
    static func tcString(key: String, fallback: String) -> String {
        let localized = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
        if localized == key {
            #if DEBUG
            print("[L10n] Missing localization key: \(key)")
            #endif
            return fallback
        }
        return localized
    }
}

func tcString(_ key: String, fallback: String) -> String {
    L10n.tcString(key: key, fallback: fallback)
}

extension Text {
    init(tcKey key: String, fallback: String) {
        self.init(verbatim: tcString(key, fallback: fallback))
    }
}
