import DyaNotchKit
import SwiftUI

struct SettingsView: View {
    @Bindable var settings: AppSettings
    let registry: PluginRegistry

    var body: some View {
        Form {
            Section("Plugins") {
                ForEach(PluginRegistry.manifests) { manifest in
                    Toggle(isOn: binding(for: manifest.id)) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(manifest.name)
                                Text(registry.failures[manifest.id] ?? manifest.summary)
                                    .font(.caption)
                                    .foregroundStyle(registry.failures[manifest.id] == nil ? Color.secondary : Color.red)
                            }
                        } icon: {
                            Image(systemName: manifest.symbol)
                        }
                    }
                }
            }

            Section("Behaviour") {
                Toggle("Expand on hover", isOn: $settings.hoverToExpand)
                Toggle("Hide when an app is fullscreen", isOn: $settings.hideInFullscreen)
                Toggle("Hide from screenshots and screen sharing", isOn: $settings.hideFromCapture)
                Toggle("Show on all displays", isOn: $settings.allDisplays)
            }

            Section("System") {
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
                if let error = settings.loginError {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
                HStack {
                    Text("Data lives in ~/Library/Application Support/DyaNotch")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Quit DyaNotch") { NSApp.terminate(nil) }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 480)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { settings.enabledPlugins.contains(id) },
            set: { on in
                if on { settings.enabledPlugins.insert(id) } else { settings.enabledPlugins.remove(id) }
            }
        )
    }
}
