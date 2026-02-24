import Foundation

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
    static func setLanguage(_ language: String) {
        defer { object_setClass(Bundle.main, BundleExtension.self) }
        // Try the specific language .lproj
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(
                Bundle.main,
                &bundleKey,
                bundle,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return
        }
        // Try Base fallback
        if let path = Bundle.main.path(forResource: "Base", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(
                Bundle.main,
                &bundleKey,
                bundle,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            return
        }
        // Try English fallback
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(
                Bundle.main,
                &bundleKey,
                bundle,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}
