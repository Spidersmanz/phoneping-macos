import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 14) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(.teal)
                    .frame(width: 60, height: 60)
                    .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text("PhonePing").font(.system(size: 26, weight: .semibold, design: .rounded))
                    Text("Your iPhone. Within earshot.").foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 18) {
                Label(model.hasPermission ? "Accessibility is enabled" : "Allow access to Find My’s controls",
                      systemImage: model.hasPermission ? "checkmark.circle.fill" : "hand.point.up.left")
                    .font(.headline)
                Text("PhonePing uses Accessibility to press Play Sound in Find My. Your Apple Account stays in Apple’s app.")
                    .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                if !model.hasPermission {
                    Button("Open Permission Settings", action: model.openPermissions)
                        .buttonStyle(.borderedProminent).tint(.teal)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your iPhone").font(.headline)
                    Spacer()
                    Button("Refresh", action: model.refresh)
                        .disabled(!model.hasPermission || model.busy)
                }
                if model.uniqueDevices.isEmpty {
                    Text(model.phoneName.isEmpty ? "Refresh to choose a phone from Find My." : model.phoneName)
                        .foregroundStyle(model.phoneName.isEmpty ? .secondary : .primary)
                } else {
                    Picker("Phone", selection: $model.phoneName) {
                        Text("Choose your iPhone…").tag("")
                        if !model.phoneName.isEmpty && !model.uniqueDevices.contains(model.phoneName) {
                            Text(model.phoneName + " (saved)").tag(model.phoneName)
                        }
                        ForEach(model.uniqueDevices, id: \.self) { name in
                            Text(name + (model.isDuplicate(name) ? " — duplicate name" : ""))
                                .tag(name).disabled(model.isDuplicate(name))
                        }
                    }.labelsHidden().disabled(model.busy)
                }
                Text("Give your phone a unique name. Then click the menu bar icon to ring it; right-click for settings.")
                    .font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: model.ping) {
                    HStack {
                        if model.busy { ProgressView().controlSize(.small) }
                        Text(model.busy ? "Working…" : "Play Sound")
                    }.frame(maxWidth: .infinity)
                }
                .controlSize(.large).buttonStyle(.borderedProminent).tint(.teal)
                .disabled(!model.ready)
            }

            if !model.message.isEmpty {
                Label(model.message, systemImage: model.failed ? "exclamationmark.circle" : "info.circle")
                    .font(.callout).foregroundStyle(model.failed ? Color.orange : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(model.message)
            }

            Divider()
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local app. Apple delivers the sound.").font(.callout).fontWeight(.medium)
                    Text("No analytics, passwords, or developer server.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if !model.phoneName.isEmpty {
                    Button("Forget", action: model.forget).buttonStyle(.link).disabled(model.busy)
                        .help("Remove the saved phone name from this Mac")
                }
            }
        }
        .padding(28)
        .frame(width: 450)
    }
}
