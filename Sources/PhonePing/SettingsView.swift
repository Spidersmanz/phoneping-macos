import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    let showAbout: () -> Void
    @State private var expandedHelp: HelpTopic?
    @State private var showingDiagnostic = false

    private enum HelpTopic: String {
        case everyday = "Using PhonePing"
        case privacy = "Privacy"
        case troubleshooting = "Troubleshooting"
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                if model.hasPermission {
                    deviceSection
                    Section {
                        LabeledContent("Find My access", value: "Allowed")
                    }
                } else {
                    permissionSection
                }

                Section {
                    helpRow(.everyday) {
                        Text("Click the menu bar icon, then choose Play Sound on your device. Opening the menu doesn’t play a sound.")
                        Text("Find My may appear behind your work while sending the request.")
                        Text("An offline device may ring when it reconnects. Press a volume button on iPhone to stop the sound.")
                    }
                    helpRow(.privacy) {
                        Text("PhonePing saves your selected device name on this Mac. Clear Selection removes that choice without removing your device from Find My.")
                        Text("No analytics, developer server, or Apple Account password access. Apple’s Find My handles sign-in and network delivery.")
                        Text("The permission allows control of other apps. PhonePing uses it only for Find My. You can revoke it in System Settings → Privacy & Security → \(AppText.permissionPane).")
                    }
                    helpRow(.troubleshooting) {
                        Text("If a request isn’t confirmed, check Find My before trying again. This preview supports Find My in English.")
                        Text("Use a unique device name without commas. After a rename, wait for Find My to show it, then refresh the list.")
                        Text("If the device list is clipped, enlarge the Find My window until all devices fit.")
                        if !model.hasPermission {
                            Text("If access still shows Required after you enable it, quit and reopen PhonePing. A local development update may require removing and re-adding the app in System Settings.")
                        }
                        Button("Run Diagnostic…") {
                            model.runDiagnostic()
                            showingDiagnostic = model.hasPermission
                        }
                        .disabled(!model.hasPermission || model.busy)
                        .help("Inspect Find My without playing a sound")
                        Text("The report omits device names and locations. It isn’t saved or uploaded.")
                    }
                } header: {
                    Text("Help")
                }
            }
            .formStyle(.grouped)

            Divider()
            HStack {
                Button("Open Find My", action: model.openFindMy)
                    .help("Bring Find My to the front")
                Spacer()
                Button("About PhonePing", action: showAbout)
            }
            .controlSize(.small)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        // Keep the window steady as help expands or the permission state changes.
        .frame(width: 480, height: 480)
        .sheet(isPresented: $showingDiagnostic, onDismiss: model.clearDiagnostic) {
            diagnosticSheet
        }
    }

    private var deviceSection: some View {
        Section {
            if !model.phoneName.isEmpty || !model.uniqueDevices.isEmpty {
                HStack(spacing: 12) {
                    Picker("Play sound on", selection: $model.phoneName) {
                        Text("Choose a Device").tag("")
                        if !model.phoneName.isEmpty && !model.uniqueDevices.contains(model.phoneName) {
                            Text(model.phoneName).tag(model.phoneName)
                        }
                        ForEach(model.uniqueDevices, id: \.self) { name in
                            Text(name + (model.isDuplicate(name) ? " (\(model.count(named: name)) devices)" : ""))
                                .tag(name).disabled(model.isDuplicate(name))
                        }
                    }
                    .disabled(model.busy)
                    .lineLimit(1)
                    .accessibilityValue(model.phoneName.isEmpty ? "No device selected" : model.phoneName)
                    .help(model.phoneName.isEmpty ? "Choose a device from Find My" : model.phoneName)
                    refreshButton
                }
                HStack {
                    if !model.phoneName.isEmpty {
                        Button("Clear Selection", action: model.forget)
                            .buttonStyle(.borderless)
                            .disabled(model.busy)
                            .help("Forget your choice in PhonePing; keep the device in Find My")
                    }
                    Spacer()
                    Button("Play Sound", action: model.ping)
                        .disabled(!model.ready)
                        .accessibilityLabel(model.phoneName.isEmpty ? "Play Sound" : "Play Sound on \(model.phoneName)")
                        .help(model.phoneName.isEmpty ? "Choose a device first" : "Request a sound on \(model.phoneName)")
                }
            } else {
                HStack(alignment: .center, spacing: 16) {
                    Text("Choose the device you want to ring.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    refreshButton
                }
            }
            if model.busy || model.needsAttention || !model.message.isEmpty {
                feedback
            }
        } header: {
            Text("Device")
        } footer: {
            if !deviceGuidance.isEmpty {
                Text(deviceGuidance)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var refreshButton: some View {
        Button(model.phoneName.isEmpty && !model.hasLoadedDevices ? "Find Devices" : "Refresh", action: model.refresh)
            .disabled(model.busy)
            .help("Read devices from Find My without playing a sound")
    }

    private var deviceGuidance: String {
        if model.busy || model.needsAttention { return "" }
        if model.uniqueDevices.contains(where: model.isDuplicate) && model.selectionIssue != .ambiguous {
            return "Devices with the same name can’t be selected. Give each a unique name, then refresh."
        }
        if model.phoneName.isEmpty {
            return model.uniqueDevices.isEmpty
                ? "Devices come from the Apple Account already signed in to Find My."
                : "Choose one device. PhonePing won’t play a sound until you ask."
        }
        return "Use the menu bar to play a sound on this device."
    }

    private var permissionSection: some View {
        Section {
            LabeledContent("Find My access", value: "Required")
            VStack(alignment: .leading, spacing: 8) {
                Text("Allow PhonePing to press Play Sound in Find My.")
                Text(AppText.permissionInstructions)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            Button("Open System Settings…", action: model.openPermissions)
            if !model.phoneName.isEmpty {
                LabeledContent("Saved device") {
                    HStack(spacing: 12) {
                        Text(model.phoneName).lineLimit(1).truncationMode(.middle)
                            .help(model.phoneName)
                        Button("Clear Selection", action: model.forget)
                            .buttonStyle(.borderless)
                            .disabled(model.busy)
                            .help("Forget your choice in PhonePing; keep the device in Find My")
                    }
                }
            }
        } header: {
            Text("Setup")
        } footer: {
            Text("This permission allows control of other apps. PhonePing uses it only for Find My.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
    }

    private func helpRow<Content: View>(_ topic: HelpTopic, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                expandedHelp = expandedHelp == topic ? nil : topic
            } label: {
                HStack {
                    Text(topic.rawValue)
                    Spacer()
                    Image(systemName: expandedHelp == topic ? "chevron.down" : "chevron.right")
                        .font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(expandedHelp == topic ? "Expanded" : "Collapsed")
            .accessibilityHint("Show or hide \(topic.rawValue.lowercased())")
            if expandedHelp == topic {
                VStack(alignment: .leading, spacing: 10, content: content)
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
            }
        }
    }

    private var feedback: some View {
        HStack(alignment: .top, spacing: 8) {
            if model.busy {
                ProgressView().controlSize(.small).accessibilityLabel(model.statusSummary)
            } else if model.needsAttention {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.secondary).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(model.statusSummary).fontWeight(.medium)
                if !model.busy && !model.statusText.isEmpty {
                    Text(model.statusText).foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }

    private var diagnosticSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Find My Diagnostic").font(.headline)
            if model.busy {
                ProgressView("Checking controls…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(model.diagnosticReport)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack {
                Text("Not saved or uploaded.").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Done") { showingDiagnostic = false }
                    .disabled(model.busy)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 500, height: 480)
        .interactiveDismissDisabled(model.busy)
        .onExitCommand {
            if !model.busy { showingDiagnostic = false }
        }
    }
}
