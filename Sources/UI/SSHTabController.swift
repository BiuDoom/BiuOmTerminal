import AppKit

class SSHTabController: NSViewController {
    // 当前SSH会话视图
    private var terminalView: TerminalView?
    
    // 标签标题
    var tabTitle: String = "SSH" {
        didSet {
            self.title = tabTitle
        }
    }
    
    // 主机配置
    var host: SSHHost? {
        didSet {
            if let host = host {
                // 更新标签标题
                tabTitle = host.nickName ?? host.username + "@" + host.hostname
                
                // 如果已经加载视图，则创建终端
                if isViewLoaded {
                    setupTerminal(with: host)
                }
            }
        }
    }
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图
        view.wantsLayer = true
        
        // 设置工具栏 (macOS中没有导航栏，使用工具栏或菜单)
        setupToolbar()
        
        // 如果有主机配置，则创建终端
        if let host = host {
            setupTerminal(with: host)
        }
    }
    
    private func setupToolbar() {
        // 创建菜单按钮
        let menuButton = NSButton(image: NSImage(named: NSImage.actionTemplateName)!, target: self, action: #selector(showMenu))
        menuButton.isBordered = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuButton)
        
        // 设置菜单按钮约束
        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            menuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }
    
    private func setupTerminal(with host: SSHHost) {
        // 清理旧的终端视图
        terminalView?.removeFromSuperview()
        terminalView?.cleanup()
        
        // 创建新的终端视图
        let newTerminalView = TerminalView(frame: view.bounds, host: host)
        view.addSubview(newTerminalView)
        
        // 设置自动布局约束
        newTerminalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newTerminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newTerminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newTerminalView.topAnchor.constraint(equalTo: view.topAnchor),
            newTerminalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 保存对终端视图的引用
        terminalView = newTerminalView
    }
    
    @objc private func showMenu() {
        let menu = NSMenu()
        
        // 复制选项
        menu.addItem(NSMenuItem(title: "复制选中文本", action: #selector(copySelectedText), keyEquivalent: "c"))
        
        // 粘贴选项
        menu.addItem(NSMenuItem(title: "粘贴", action: #selector(pasteText), keyEquivalent: "v"))
        
        // 搜索选项
        menu.addItem(NSMenuItem(title: "搜索", action: #selector(showSearchDialog), keyEquivalent: "f"))
        
        // 保存历史选项
        menu.addItem(NSMenuItem(title: "保存历史", action: #selector(saveTerminalHistory), keyEquivalent: "s"))
        
        // 分隔线
        menu.addItem(NSMenuItem.separator())
        
        // 断开连接选项
        menu.addItem(NSMenuItem(title: "断开连接", action: #selector(disconnectSession), keyEquivalent: "d"))
        
        // 显示菜单
        let event = NSApplication.shared.currentEvent ?? NSEvent()
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }
    
    @objc private func copySelectedText() {
        terminalView?.copySelection()
    }
    
    @objc private func pasteText() {
        terminalView?.paste()
    }
    
    @objc private func showSearchDialog() {
        let alert = NSAlert()
        alert.messageText = "搜索"
        alert.informativeText = "输入要搜索的文本"
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        alert.accessoryView = textField
        
        alert.addButton(withTitle: "搜索")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        
        if response == .alertFirstButtonReturn {
            let searchText = textField.stringValue
            if !searchText.isEmpty {
                terminalView?.search(text: searchText)
            }
        }
    }
    
    @objc private func saveTerminalHistory() {
        let savePanel = NSSavePanel()
        savePanel.title = "保存终端历史"
        savePanel.nameFieldStringValue = "terminal_history.txt"
        savePanel.allowedFileTypes = ["txt"]
        
        savePanel.beginSheetModal(for: self.view.window!) { response in
            if response == .OK, let url = savePanel.url {
                if self.terminalView?.saveHistory(to: url) == true {
                    // 显示成功消息
                    let alert = NSAlert()
                    alert.messageText = "成功"
                    alert.informativeText = "终端历史已保存"
                    alert.runModal()
                } else {
                    // 显示错误消息
                    let alert = NSAlert()
                    alert.messageText = "错误"
                    alert.informativeText = "保存终端历史失败"
                    alert.runModal()
                }
            }
        }
    }
    
    @objc private func disconnectSession() {
        terminalView?.cleanup()
        
        // 通知关闭此标签或窗口
        // macOS中我们通常直接关闭窗口
        self.view.window?.close()
        
        // 或者发送通知，让其他控制器处理
        NotificationCenter.default.post(name: NSNotification.Name("CloseSSHTab"), object: self)
    }
}
