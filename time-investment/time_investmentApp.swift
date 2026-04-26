//
//  time_investmentApp.swift
//  time-investment
//
//  Created by wangzhengqing on 2026/4/20.
//

import SwiftUI

@main
struct time_investmentApp: App {
    /// 应用级共享容器：
    /// - 持有仓储、追踪、设置等跨页面状态
    /// - 通过 StateObject 保证整个 App 生命周期仅初始化一次
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            // 主窗口将容器注入根视图，所有页面都从同一个数据源读取状态。
            ContentView(container: container)
        }

#if os(macOS)
        // macOS 专属菜单栏入口：
        // 与主窗口共享同一个 container，因此数值与开关状态实时一致。
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
                    // 菜单栏直接修改 settings，再交由容器统一持久化与副作用处理。
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
