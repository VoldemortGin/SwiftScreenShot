//
//  SettingsView.swift
//  SwiftScreenShot
//
//  Settings view using SwiftUI
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: ScreenshotSettings
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // General Settings Tab
            generalSettingsView
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }
                .tag(0)

            // Error Recovery Tab
            ErrorRecoverySettingsView(settings: settings)
                .tabItem {
                    Label("错误恢复", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(1)

            // Shortcuts Tab
            shortcutsView
                .tabItem {
                    Label("快捷键", systemImage: "command")
                }
                .tag(2)
        }
        .frame(width: 600, height: 650)
    }

    private var generalSettingsView: some View {
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
                Toggle("播放截图音效", isOn: $settings.playSoundOnCapture)
                    .help("截图成功时播放快门音效")
                Toggle("截图后自动编辑", isOn: $settings.autoEditAfterCapture)
                    .help("截图完成后自动打开编辑工具，可添加箭头、文字、马赛克等标注")

                Picker("默认延时时长:", selection: $settings.defaultDelayTime) {
                    Text("3秒").tag(3)
                    Text("5秒").tag(5)
                    Text("10秒").tag(10)
                }
                .pickerStyle(.segmented)
                .help("设置延时截图的默认延迟时间")
            }

            Section(header: Text("历史记录")) {
                Toggle("自动保存到历史", isOn: $settings.autoSaveToHistory)
                    .help("自动保存每次截图到历史记录")

                Picker("历史数量上限:", selection: $settings.historyMaxCount) {
                    Text("10张").tag(10)
                    Text("20张").tag(20)
                    Text("50张").tag(50)
                }
                .pickerStyle(.segmented)
                .help("历史记录保存的最大截图数量（固定的截图不受限制）")

                HStack {
                    Text("存储位置:")
                    Spacer()
                    if settings.historyStoragePath.isEmpty {
                        Text("默认位置")
                            .foregroundColor(.secondary)
                    } else {
                        Text(settings.historyStoragePath)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Button(settings.historyStoragePath.isEmpty ? "选择..." : "重置") {
                        if settings.historyStoragePath.isEmpty {
                            selectHistoryPath()
                        } else {
                            settings.historyStoragePath = ""
                        }
                    }
                }
            }

        }
        .formStyle(.grouped)
        .padding()
    }

    private var shortcutsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("快捷键说明")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("截图操作")
                    .font(.headline)
                Text("截图: ⌃⌘A (Control + Command + A)")
                    .foregroundColor(.secondary)
                Text("取消: ESC")
                    .foregroundColor(.secondary)
                Text("确认: Enter")
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("编辑器快捷键")
                    .font(.headline)
                Text("撤销: ⌘Z")
                    .foregroundColor(.secondary)
                Text("重做: ⌘⇧Z")
                    .foregroundColor(.secondary)
                Text("保存: ⌘S")
                    .foregroundColor(.secondary)
                Text("取消编辑: ESC")
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("历史记录")
                    .font(.headline)
                Text("打开历史: ⌘H")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
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

    private func selectHistoryPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "选择历史记录存储位置"

        if panel.runModal() == .OK, let url = panel.url {
            settings.historyStoragePath = url.path
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(settings: ScreenshotSettings())
    }
}
