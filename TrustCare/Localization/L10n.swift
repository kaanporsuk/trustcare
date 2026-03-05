import Foundation
import SwiftUI

enum L10n {
    private static var warnedMissingKeys: Set<String> = []
    private static let warningLock = NSLock()

    static func tcString(_ key: String, fallback: String) -> String {
        let localized = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
        if localized == key {
            #if DEBUG
            warningLock.lock()
            let shouldWarn = warnedMissingKeys.insert(key).inserted
            warningLock.unlock()
            if shouldWarn {
                print("[L10n] Missing localization key: \(key)")
            }
            #endif
            return fallback
        }
        return localized
    }
}

func tcString(_ key: String, fallback: String) -> String {
    L10n.tcString(key, fallback: fallback)
}

extension Text {
    init(tcKey: String, fallback: String) {
        self.init(verbatim: L10n.tcString(tcKey, fallback: fallback))
    }
}
