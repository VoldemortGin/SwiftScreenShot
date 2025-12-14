//
//  HistoryView.swift
//  SwiftScreenShot
//
//  SwiftUI view for screenshot history
//

import SwiftUI
import AppKit

struct HistoryView: View {
    @StateObject private var history = ScreenshotHistory.shared
    @State private var searchText = ""
    @State private var selectedDateFilter: ScreenshotHistory.DateFilter? = nil
    @State private var selectedItem: ScreenshotHistoryItem? = nil
    @State private var showingPreview = false
    @State private var showingDeleteAlert = false
    @State private var showingClearAlert = false

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 16)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索格式...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .frame(width: 200)

                // Date filter
                Picker("", selection: $selectedDateFilter) {
                    Text("全部").tag(nil as ScreenshotHistory.DateFilter?)
                    Divider()
                    Text("今天").tag(ScreenshotHistory.DateFilter.today as ScreenshotHistory.DateFilter?)
                    Text("昨天").tag(ScreenshotHistory.DateFilter.yesterday as ScreenshotHistory.DateFilter?)
                    Text("最近7天").tag(ScreenshotHistory.DateFilter.lastWeek as ScreenshotHistory.DateFilter?)
                    Text("最近30天").tag(ScreenshotHistory.DateFilter.lastMonth as ScreenshotHistory.DateFilter?)
                }
                .frame(width: 120)

                Spacer()

                // Info
                Text("\(filteredItems.count) 张截图")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))

                // Clear history button
                Button(action: {
                    showingClearAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("清空历史")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(history.items.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Content
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredItems) { item in
                            HistoryItemView(item: item) { action in
                                handleAction(action, for: item)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            if let item = selectedItem {
                PreviewView(item: item)
            }
        }
        .alert("删除截图", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let item = selectedItem {
                    history.deleteItem(item)
                }
            }
        } message: {
            Text("确定要删除这张截图吗？此操作不可撤销。")
        }
        .alert("清空历史", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("仅删除未固定", role: .destructive) {
                history.clearHistory(keepPinned: true)
            }
            Button("全部删除", role: .destructive) {
                history.clearHistory(keepPinned: false)
            }
        } message: {
            Text("选择清空方式：")
        }
    }

    private var filteredItems: [ScreenshotHistoryItem] {
        history.filterItems(searchText: searchText, dateFilter: selectedDateFilter)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("暂无截图历史")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("截图会自动保存到历史记录")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handleAction(_ action: HistoryItemAction, for item: ScreenshotHistoryItem) {
        selectedItem = item

        switch action {
        case .preview:
            showingPreview = true

        case .copyToClipboard:
            if let image = history.loadFullImage(for: item) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.writeObjects([image])

                // Show temporary feedback
                showTemporaryNotification(message: "已复制到剪贴板")
            }

        case .edit:
            if let image = history.loadFullImage(for: item) {
                NotificationCenter.default.post(
                    name: .openEditor,
                    object: image
                )
            }

        case .togglePin:
            history.togglePin(for: item)

        case .delete:
            showingDeleteAlert = true
        }
    }

    private func showTemporaryNotification(message: String) {
        // This would show a temporary HUD notification
        // For simplicity, we'll just use the standard notification
        let content = UNMutableNotificationContent()
        content.title = message
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

enum HistoryItemAction {
    case preview
    case copyToClipboard
    case edit
    case togglePin
    case delete
}

// MARK: - History Item View

struct HistoryItemView: View {
    let item: ScreenshotHistoryItem
    let onAction: (HistoryItemAction) -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack(alignment: .topTrailing) {
                if let thumbnail = item.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(height: 140)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        )
                }

                // Pin indicator
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
                        .clipShape(Circle())
                        .padding(6)
                }

                // Hover overlay with actions
                if isHovered {
                    HStack(spacing: 8) {
                        ActionButton(icon: "eye", tooltip: "预览") {
                            onAction(.preview)
                        }

                        ActionButton(icon: "doc.on.clipboard", tooltip: "复制") {
                            onAction(.copyToClipboard)
                        }

                        ActionButton(icon: "pencil", tooltip: "编辑") {
                            onAction(.edit)
                        }

                        ActionButton(
                            icon: item.isPinned ? "pin.slash" : "pin",
                            tooltip: item.isPinned ? "取消固定" : "固定"
                        ) {
                            onAction(.togglePin)
                        }

                        ActionButton(icon: "trash", tooltip: "删除", isDestructive: true) {
                            onAction(.delete)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                    .transition(.opacity)
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.formattedDate)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)

                HStack {
                    Text(item.imageFormat.uppercased())
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)

                    Text("·")
                        .foregroundColor(.secondary)

                    Text(item.formattedFileSize)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ActionButton: View {
    let icon: String
    let tooltip: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(isDestructive ? .red : .white)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Preview View

struct PreviewView: View {
    let item: ScreenshotHistoryItem
    @Environment(\.dismiss) var dismiss
    @State private var image: NSImage?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("截图预览")
                        .font(.headline)
                    Text(item.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("关闭") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Image
            if let image = image {
                GeometryReader { geometry in
                    ScrollView([.horizontal, .vertical]) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                minWidth: geometry.size.width,
                                minHeight: geometry.size.height
                            )
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            // Footer
            HStack {
                Text("\(item.imageFormat.uppercased()) · \(item.formattedFileSize)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button("复制") {
                    if let image = image {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.writeObjects([image])
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 800, height: 600)
        .onAppear {
            image = ScreenshotHistory.shared.loadFullImage(for: item)
        }
    }
}

import UserNotifications
