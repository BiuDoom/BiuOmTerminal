import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindow: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 创建主窗口
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        mainWindow.title = "BiuOmTerminal"
        mainWindow.center()
        
        // 创建主控制器
        let mainViewController = MainViewController()
        mainWindow.contentViewController = mainViewController
        
        // 显示窗口
        mainWindow.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// 主控制器
class MainViewController: NSViewController {
    // 添加创建SSH会话的按钮
    private let newSessionButton = NSButton()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图
        view.wantsLayer = true
        
        // 设置新建会话按钮
        newSessionButton.title = "新建SSH会话"
        newSessionButton.bezelStyle = .rounded
        newSessionButton.target = self
        newSessionButton.action = #selector(createNewSession)
        
        view.addSubview(newSessionButton)
        newSessionButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            newSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newSessionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func createNewSession() {
        // 创建设置控制器
        let settingsController = SSHSettingsController()
        settingsController.completion = { [weak self] host in
            guard let host = host else { return }
            
            // 保存主机配置
            SSHHostsManager.shared.addHost(host)
            
            // 创建新的SSH会话
            self?.openSSHSession(with: host)
        }
        
        // 打开设置窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SSH设置"
        window.contentViewController = settingsController
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    private func openSSHSession(with host: SSHHost) {
        // 创建SSH会话窗口
        let tabController = SSHTabController()
        tabController.host = host
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = host.nickName ?? "\(host.username)@\(host.hostname)"
        window.contentViewController = tabController
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

// 创建应用程序
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
