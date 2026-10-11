import Foundation

public enum PingError: Error, LocalizedError, Equatable {
    case permission, appUnavailable, unsupportedInterface, notFound, ambiguous, invalidName
    case unavailableAction, actionFailed, busy

    public var errorDescription: String? {
        switch self {
        case .permission: return "Allow PhonePing in System Settings → Privacy & Security → Accessibility, then try again."
        case .appUnavailable: return "Find My could not be opened. Open it manually and check that you’re signed in."
        case .unsupportedInterface: return "PhonePing couldn’t safely read Find My. Open its Devices tab, dismiss any dialogs, and try again. This preview supports the English Find My interface."
        case .notFound: return "Your saved phone wasn’t found. Check its name in Find My, then refresh the device list."
        case .ambiguous: return "More than one device has that name. Give your iPhone a unique name in Settings → General → About → Name, then wait for Find My to update."
        case .invalidName: return "Choose a device with a nonempty, unique name without commas."
        case .unavailableAction: return "Find My hasn’t exposed a Play Sound action for this device. Open the phone in Find My and try again."
        case .actionFailed: return "Find My didn’t accept the sound action. Open Find My to check the phone."
        case .busy: return "A request is already in progress."
        }
    }
}

/// Find My exposes device names and status in a comma-separated accessibility label.
/// Never persist the status suffix: it may contain a location or battery information.
public enum DevicePolicy {
    public static func name(from label: String) -> String {
        String(label.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false).first ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func validate(_ name: String) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !name.contains(","), !name.contains("\n") else { throw PingError.invalidName }
    }

    public static func uniqueIndex(named name: String, in names: [String]) throws -> Int {
        try validate(name)
        let matches = names.indices.filter { names[$0] == name }
        guard !matches.isEmpty else { throw PingError.notFound }
        guard matches.count == 1 else { throw PingError.ambiguous }
        return matches[0]
    }

    /// Exact allowlist, never substring-match a potentially destructive action.
    public static func isPlayAction(_ description: String) -> Bool {
        ["Play", "Play Sound"].contains(description)
    }

    public static func canPlay(expectedName: String, detailNames: [String], buttonLabel: String, enabled: Bool) -> Bool {
        guard detailNames == [expectedName], enabled else { return false }
        let parts = buttonLabel.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        return parts.count == 2 && isPlayAction(parts[0]) && parts[1] == "Off"
    }
}
