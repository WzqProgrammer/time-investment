//
//  time_investmentApp.swift
//  time-investment
//
//  Created by wangzhengqing on 2026/4/20.
//

import SwiftUI

@main
struct time_investmentApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }

#if os(macOS)
        MenuBarExtra(
            "¥\(container.todaySummary.totalValue, specifier: "%.0f") | \(container.todaySummary.totalSeconds / 3600, specifier: "%.1f")h",
            systemImage: "clock.badge.checkmark"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    String(
                        format: String(localized: "menubar.todayValue"),
                        locale: Locale.current,
                        container.todaySummary.totalValue
                    )
                )
                Text(
                    String(
                        format: String(localized: "menubar.todayHours"),
                        locale: Locale.current,
                        container.todaySummary.totalSeconds / 3600
                    )
                )
                Divider()
                Button(
                    container.settings.autoTrackingEnabled
                        ? String(localized: "menubar.stopAutoTracking")
                        : String(localized: "menubar.startAutoTracking")
                ) {
                    var settings = container.settings
                    settings.autoTrackingEnabled.toggle()
                    container.saveSettings(settings)
                }
            }
            .padding()
        }
#endif
    }
}
