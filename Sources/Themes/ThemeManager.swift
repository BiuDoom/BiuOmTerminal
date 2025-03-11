import Foundation
import SwiftTerm

class ThemeManager {
    // 这个类大部分内容可以保持不变，因为它处理的是数据逻辑
    // 只需要将UIColor替换为NSColor
    
    // 单例模式
    static let shared = ThemeManager()
    
    // 预定义主题
    private var themes: [String: TerminalTheme] = [:]
    
    // 用户自定义主题
    private var userThemes: [String: TerminalTheme] = [:]
    
    private init() {
        // 初始化预定义主题
        setupDefaultThemes()
        // 加载用户主题
        loadUserThemes()
    }
    
    private func setupDefaultThemes() {
        // 添加默认主题
        themes["default"] = TerminalTheme.defaultDark()
        
        // Solarized Dark
        let solarizedDark = TerminalTheme()
        solarizedDark.background = Color.init(hex: "#002b36")
        // ... 其余代码保持不变 ...
    }
    
    // ... 其余方法保持不变 ...
}
