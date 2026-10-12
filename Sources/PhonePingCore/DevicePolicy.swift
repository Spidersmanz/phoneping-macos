import Foundation

public enum PingError: Error, LocalizedError, Equatable {
    case permission, appUnavailable, unsupportedInterface, notFound, ambiguous, invalidName
    case unavailableAction, actionFailed, requestUncertain, discoveryTimedOut, incompleteList, detailsChanged, busy

    public var title: String {
        switch self {
        case .permission: return "Permission required"
        case .appUnavailable: return "Find My couldn’t open"
        case .unsupportedInterface: return "Open Find My to continue"
        case .notFound: return "Device not found"
        case .ambiguous: return "Devices share this name"
        case .invalidName: return "Choose a different device name"
        case .unavailableAction: return "Play Sound is unavailable"
        case .actionFailed: return "Couldn’t complete the request"
        case .requestUncertain: return "Sound request not confirmed"
        case .discoveryTimedOut: return "Find My didn’t respond"
        case .detailsChanged: return "Couldn’t verify the device"
        case .incompleteList: return "Show the full device list"
        case .busy: return "Request in progress"
        }
    }

    public var errorDescription: String? {
        switch self {
        case .permission: return "Allow PhonePing in System Settings to use Find My."
        case .appUnavailable: return "Open Find My and check that you’re signed in."
        case .unsupportedInterface: return "Open Find My, select Devices, then try again. This preview requires Find My in English."
        case .notFound: return "Check the device’s name in Find My, then refresh the list."
        case .ambiguous: return "More than one device has this name. Choose a device with a unique name in Find My."
        case .invalidName: return "Choose a device with a name that doesn’t contain commas or line breaks."
        case .unavailableAction: return "PhonePing couldn’t find an available Play Sound control. Open Find My to check the device."
        case .actionFailed: return "Open Find My to check the device, then try again."
        case .requestUncertain: return "The request may have been sent. Check Find My before trying again."
        case .discoveryTimedOut: return "No sound was requested. Open Find My and try again."
        case .detailsChanged: return "The open device details don’t match your selection. No sound was requested. Open Find My and refresh your devices."
        case .incompleteList: return "Open Find My and enlarge its window so all devices fit. PhonePing can’t safely choose from an incomplete or scrolling list."
        case .busy: return "Wait for the current request to finish."
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
              !name.contains(","), name.rangeOfCharacter(from: .newlines) == nil else { throw PingError.invalidName }
    }

    /// A nil list is an unrefreshed saved selection, to be checked at request time.
    public static func selectionIssue(named name: String, in names: [String]?) -> PingError? {
        do {
            try validate(name)
            if let names { _ = try uniqueIndex(named: name, in: names) }
            return nil
        } catch { return error as? PingError ?? .invalidName }
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
