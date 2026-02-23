import Foundation

private var bundleKey: UInt8 = 0

final class BundleExtension: Bundle {
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
        let path = Bundle.main.path(forResource: language, ofType: "lproj")
            ?? Bundle.main.path(forResource: "en", ofType: "lproj")
        guard let path else { return }
        objc_setAssociatedObject(
            Bundle.main,
            &bundleKey,
            Bundle(path: path),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
