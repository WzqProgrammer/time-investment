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
                Text("今日时间价值：¥\(container.todaySummary.totalValue, specifier: "%.2f")")
                Text("今日时长：\(container.todaySummary.totalSeconds / 3600, specifier: "%.1f") 小时")
                Divider()
                Button(container.settings.autoTrackingEnabled ? "停止自动追踪" : "启动自动追踪") {
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
