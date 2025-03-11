#if canImport(UIKit)
import UIKit
typealias PlatformViewController = UIViewController
typealias PlatformView = UIView
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
#else
import AppKit
typealias PlatformViewController = NSViewController
typealias PlatformView = NSView
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
#endif
import SwiftTerm

class TerminalViewController: UIViewController {
    
    // Terminal视图
    var terminal: Terminal!
    
    // 搜索状态
    private var isSearching: Bool = false
    private var searchText: String = ""
    private var searchResults: [TerminalSearchResult] = []
    private var currentSearchResultIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTerminal()
    }
    
    private func setupTerminal() {
        // 创建Terminal视图
        terminal = Terminal(frame: view.bounds)
        terminal.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // 添加到视图层次结构
        view.addSubview(terminal)
        
        // 设置默认字体
        terminal.font = UIFont(name: "Menlo", size: 14.0)
        
        // 设置默认主题
        let defaultTheme = ThemeManager.shared.getTheme(named: "default") ?? TerminalTheme.defaultDark()
        terminal.applyTheme(defaultTheme)
        
        // 设置终端委托
        terminal.delegate = self
    }
    
    // 搜索功能
    func search(text: String, caseSensitive: Bool = false, regex: Bool = false) {
        guard !text.isEmpty else {
            clearSearch()
            return
        }
        
        searchText = text
        isSearching = true
        
        // 执行搜索
        searchResults = terminal.search(
            for: text,
            caseSensitive: caseSensitive,
            regex: regex
        )
        
        if !search
