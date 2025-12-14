//
//  ErrorRecoverySettingsView.swift
//  SwiftScreenShot
//
//  Error recovery settings UI
//

import SwiftUI
import UserNotifications

struct ErrorRecoverySettingsView: View {
    @ObservedObject var settings: ScreenshotSettings
    @State private var showingErrorLog = false
    @State private var errorStats: [String: Any] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("错误恢复设置")
                .font(.title2)
                .fontWeight(.bold)

            // Auto Retry Toggle
            Toggle("启用自动重试", isOn: $settings.autoRetryEnabled)
                .help("截图失败时自动重试")

            if settings.autoRetryEnabled {
                VStack(alignment: .leading, spacing: 15) {
                    // Max Retry Attempts
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("最大重试次数:")
                                .frame(width: 120, alignment: .leading)
                            Stepper(
                                "\(settings.maxRetryAttempts) 次",
                                value: $settings.maxRetryAttempts,
                                in: 1...5
                            )
                        }
                        Text("推荐设置为 3 次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Retry Interval Multiplier
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text("重试间隔倍数:")
                                .frame(width: 120, alignment: .leading)
                            Slider(
                                value: $settings.retryIntervalMultiplier,
                                in: 0.5...2.0,
                                step: 0.25
                            )
                            Text(String(format: "%.2fx", settings.retryIntervalMultiplier))
                                .frame(width: 50)
                        }
                        Text("基础间隔：0.5秒、1秒、2秒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("当前间隔：\(formatRetryIntervals())")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.leading, 20)
            }

            Divider()

            // Error Statistics
            VStack(alignment: .leading, spacing: 10) {
                Text("错误统计")
                    .font(.headline)

                HStack {
                    Text("活跃重试:")
                    Text("\(errorStats["activeRetries"] as? Int ?? 0)")
                        .foregroundColor(.blue)
                }

                HStack {
                    Text("重试状态:")
                    if let enabled = errorStats["retryEnabled"] as? Bool {
                        Text(enabled ? "已启用" : "已禁用")
                            .foregroundColor(enabled ? .green : .red)
                    }
                }

                Button("刷新统计") {
                    loadErrorStatistics()
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // Error Log Management
            VStack(alignment: .leading, spacing: 10) {
                Text("错误日志")
                    .font(.headline)

                HStack(spacing: 10) {
                    Button("查看日志") {
                        ErrorLogger.shared.showLogFile()
                    }
                    .buttonStyle(.bordered)

                    Button("导出日志") {
                        exportErrorLog()
                    }
                    .buttonStyle(.bordered)

                    Button("清除日志") {
                        clearErrorLog()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }

                Text("日志会自动保留 7 天")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Error Recovery Help
            VStack(alignment: .leading, spacing: 10) {
                Text("错误类型说明")
                    .font(.headline)

                ErrorTypeHelpView()
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
        .onAppear {
            loadErrorStatistics()
        }
    }

    private func formatRetryIntervals() -> String {
        let baseDelays = [0.5, 1.0, 2.0]
        let adjustedDelays = baseDelays.map { $0 * settings.retryIntervalMultiplier }
        let formatted = adjustedDelays.prefix(settings.maxRetryAttempts).map { String(format: "%.1f秒", $0) }
        return formatted.joined(separator: "、")
    }

    private func loadErrorStatistics() {
        errorStats = ErrorRecoveryManager.shared.getRetryStatistics()
    }

    private func exportErrorLog() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "error_log_\(DateFormatter.yyyyMMdd.string(from: Date())).txt"

        if panel.runModal() == .OK, let url = panel.url {
            let report = ErrorLogger.shared.generateErrorReport()
            try? report.write(to: url, atomically: true, encoding: .utf8)

            // Show success notification
            let content = UNMutableNotificationContent()
            content.title = "日志已导出"
            content.body = url.lastPathComponent
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    private func clearErrorLog() {
        let alert = NSAlert()
        alert.messageText = "确认清除日志？"
        alert.informativeText = "此操作将清除所有错误日志记录，无法恢复。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            ErrorLogger.shared.clearLogs()
        }
    }
}

// MARK: - Error Type Help View

struct ErrorTypeHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ErrorTypeRow(
                icon: "lock.shield",
                title: "权限错误",
                description: "需要授予屏幕录制权限",
                color: .red,
                isRecoverable: false
            )

            ErrorTypeRow(
                icon: "exclamationmark.triangle",
                title: "系统繁忙",
                description: "系统资源暂时不足，自动重试",
                color: .orange,
                isRecoverable: true
            )

            ErrorTypeRow(
                icon: "externaldrive.badge.exclamationmark",
                title: "磁盘空间不足",
                description: "需要清理磁盘空间",
                color: .red,
                isRecoverable: false
            )

            ErrorTypeRow(
                icon: "wifi.slash",
                title: "网络错误",
                description: "云同步失败，将延迟重试",
                color: .orange,
                isRecoverable: true
            )

            ErrorTypeRow(
                icon: "questionmark.circle",
                title: "未知错误",
                description: "将尝试自动重试",
                color: .gray,
                isRecoverable: true
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ErrorTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isRecoverable: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isRecoverable {
                        Text("可重试")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    } else {
                        Text("需操作")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

struct ErrorRecoverySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorRecoverySettingsView(settings: ScreenshotSettings())
    }
}
