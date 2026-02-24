import Foundation
import ObjectiveC

// MARK: - Runtime Language Bundle Swizzle
//
// Replaces Bundle.main's string lookup to use a specific .lproj folder,
// enabling runtime language switching.
//
// IMPORTANT: This only works if the .lproj folders exist in the built app
// bundle. Ensure all languages are added to the Xcode project's
// Localizations settings (Project → Info → Localizations).

private var bundleKey: UInt8 = 0

final class BundleExtension: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Swizzles the main bundle to return strings from a specific language.
    static func setLanguage(_ language: String) {
        guard !language.isEmpty else { return }

        defer { object_setClass(Bundle.main, BundleExtension.self) }

        // Try exact match (e.g., "tr.lproj")
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(
                Bundle.main,
                &bundleKey,
                bundle,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            print("✅ Language bundle set to: \(path)")
            return
        }

        // Try with region variants (e.g., "de-DE.lproj")
        for variant in ["\(language)-\(language.uppercased())", "\(language)-US", "\(language)-GB"] {
            if let path = Bundle.main.path(forResource: variant, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                objc_setAssociatedObject(
                    Bundle.main,
                    &bundleKey,
                    bundle,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
                print("✅ Language bundle set to: \(path)")
                return
            }
        }

        // Fallback to Base
        if let path = Bundle.main.path(forResource: "Base", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(
                Bundle.main,
                &bundleKey,
                bundle,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            print("⚠️ No .lproj for '\(language)', using Base.lproj")
            return
        }

        // Final fallback to English
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(
                Bundle.main,
                &bundleKey,
                bundle,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            print("⚠️ No .lproj for '\(language)', using en.lproj fallback")
        } else {
            print("❌ WARNING: No .lproj found for '\(language)'. Language switch will NOT work.")
            if let resourcePath = Bundle.main.resourcePath {
                let contents = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath)) ?? []
                for item in contents where item.hasSuffix(".lproj") {
                    print("   Available: \(item)")
                }
            }
        }
    }
}
