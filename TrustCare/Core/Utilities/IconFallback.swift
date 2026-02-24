import UIKit

/// Returns a safe SF Symbol name for a specialty icon.
/// Falls back to "cross.case" if the original icon is nil, empty,
/// or unavailable on this iOS version.
func safeIconName(_ iconName: String?) -> String {
    guard let name = iconName, !name.isEmpty else {
        return "cross.case"
    }
    // Verify the icon exists at runtime
    if UIImage(systemName: name) != nil {
        return name
    }
    return "cross.case"
}
