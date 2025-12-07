//
//  SettingsView.swift
//  SwiftScreenShot
//
//  Settings view using SwiftUI
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: ScreenshotSettings

    var body: some View {
        Form {
            Section(header: Text("保存设置")) {
                Toggle("同时保存到文件", isOn: $settings.shouldSaveToFile)

                if settings.shouldSaveToFile {
                    HStack {
                        Text("保存路径:")
                        Spacer()
                        if let savePath = settings.savePath {
                            Text(savePath.path)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Button("选择...") {
                            selectSavePath()
                        }
                    }

                    Picker("图像格式:", selection: Binding(
                        get: { settings.imageFormat.rawValue },
                        set: { settings.imageFormat = ImageFormat(rawValue: $0) ?? .png }
                    )) {
                        Text("PNG").tag("png")
                        Text("JPEG").tag("jpeg")
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section(header: Text("应用设置")) {
                Toggle("开机自动启动", isOn: $settings.launchAtLogin)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("快捷键")
                        .font(.headline)
                    Text("截图: ⌃⌘A (Control + Command + A)")
                        .foregroundColor(.secondary)
                    Text("取消: ESC")
                        .foregroundColor(.secondary)
                    Text("确认: Enter")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
    }

    private func selectSavePath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        if panel.runModal() == .OK {
            settings.savePath = panel.url
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: ScreenshotSettings())
    }
}
