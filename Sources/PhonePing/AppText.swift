import Foundation

enum AppText {
    static let noDevicesTitle = "No devices found"
    static let noDevicesMessage = "Open Find My to check your devices, then refresh the list."

    static var permissionPane: String {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27
            ? "Device Control and Data Access" : "Accessibility"
    }

    static var permissionInstructions: String {
        "Enable PhonePing in System Settings → Privacy & Security → \(permissionPane)."
    }
}
