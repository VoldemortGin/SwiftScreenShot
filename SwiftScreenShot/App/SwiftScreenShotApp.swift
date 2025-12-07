//
//  SwiftScreenShotApp.swift
//  SwiftScreenShot
//
//  Main application entry point
//

import SwiftUI

@main
struct SwiftScreenShotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
