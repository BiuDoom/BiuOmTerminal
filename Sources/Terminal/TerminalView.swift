import AppKit
import SwiftTerm
import Shout

class TerminalView: NSView, TerminalViewDelegate {
    private var terminalView: TerminalView!
    private var sshSession: SSHSession?
    private var shellSession: ShellSession?
    private var dataQueue = DispatchQueue(label: "com.biuom.terminaldata")
    private var isReading = false
    
    // 终端配置
    var fontSize: CGFloat = 12.0 {
        didSet {
            updateTerminalFont()
        }
    }
    
    var fontFamily: String = "Menlo" {
        didSet {
            updateTerminalFont()
        }
    }
    
    // 终端初始化参数
    init(frame: NSRect, host: SSHHost) {
        super.init(frame: frame)
        
        setupTerminal()
        
        // 连接到SSH服务器
        connectSSH(host: host)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupTerminal()
    }
    
    private func setupTerminal() {
        // 创建SwiftTerm终端视图
        terminalView = TerminalView(frame: bounds)
        terminalView.autoresizingMask = [.width, .height]
        terminalView.delegate = self
        addSubview(terminalView)
        
        // 配置终端
        updateTerminalFont()
        
        // 配置终端颜色
        let colorScheme = ThemeManager.shared.getTheme(named: "default") ?? TerminalTheme.defaultDark()
        terminalView.terminal.applyTheme(colorScheme)
    }
    
    private func updateTerminalFont() {
        guard let font = NSFont(name: fontFamily, size: fontSize) else {
            return
        }
        
        terminalView.terminal.font = font
    }
    
    // 连接SSH
    func connectSSH(host: SSHHost) {
        SSHManager.shared.connect(host: host) { result in
            switch result {
            case .success(let session):
                self.sshSession = session
                self.openShell()
            case .failure(let error):
                self.showError(message: "Failed to connect: \(error.localizedDescription)")
            }
        }
    }
    
    // 打开Shell
    private func openShell() {
        guard let session = sshSession else {
            showError(message: "No active SSH session")
            return
        }
        
        guard let shellSession = session.createShellSession() else {
            showError(message: "Failed to create shell session")
            return
        }
        
        self.shellSession = shellSession
        
        // 设置终端大小
        let size = terminalView.terminal.getTerminalSize()
        try? shellSession.setTerminalSize(width: UInt(size.width), height: UInt(size.height))
        
        // 开始读取数据
        self.startReading()
        
        // 发送终端类型信息
        let termInfoCmd = "export TERM=xterm-256color\r"
        try? shellSession.write(termInfoCmd)
        
        // 告诉终端已准备好接收数据
        DispatchQueue.main.async {
            self.terminalView.terminal.ready = true
        }
    }
    
    // 开始读取Shell输出
    private func startReading() {
        guard let shellSession = self.shellSession, !isReading else { return }
        
        isReading = true
        
        dataQueue.async {
            let bufferSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            while self.isReading {
                do {
                    let bytesRead = try shellSession.read(&buffer)
                    if bytesRead > 0 {
                        let data = Data(buffer[0..<bytesRead])
                        DispatchQueue.main.async {
                            self.terminalView.terminal.feed(data: data)
                        }
                    } else if bytesRead == 0 {
                        // 连接关闭
                        DispatchQueue.main.async {
                            self.showError(message: "Connection closed")
                            self.isReading = false
                        }
                        break
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.showError(message: "Error reading from shell: \(error.localizedDescription)")
                        self.isReading = false
                    }
                    break
                }
            }
        }
    }
    
    // 发送数据到Shell
    func sendString(_ string: String) {
        guard let shellSession = shellSession else { return }
        
        do {
            try shellSession.write(string)
        } catch {
            showError(message: "Error sending data: \(error.localizedDescription)")
        }
    }
    
    // 错误处理
    private func showError(message: String) {
        // 在终端中显示错误信息
        let errorMsg = "\r\n\u{001B}[31m[ERROR] \(message)\u{001B}[0m\r\n"
        terminalView.terminal.feed(text: errorMsg)
    }
    
    // TerminalViewDelegate实现
    func send(source: TerminalView, data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        sendString(string)
    }
    
    // 处理终端大小变化
    func sizeChanged(source: TerminalView, newCols: Int, newRows: Int) {
        try? shellSession?.setTerminalSize(width: UInt(newCols), height: UInt(newRows))
    }
    
    // 清理资源
    func cleanup() {
        isReading = false
        shellSession = nil
        
        if let session = sshSession {
            session.disconnect()
            sshSession = nil
        }
    }
    
    deinit {
        cleanup()
    }
    
    // 搜索功能
    func search(text: String, caseSensitive: Bool = false, regex: Bool = false) {
        // 实现与之前相同...
    }
    
    // 保存终端历史到文件
    func saveHistory(to url: URL) -> Bool {
        // 实现与之前相同...
        return false
    }
}

// 添加复制粘贴功能
extension TerminalView {
    @objc func copySelection() {
        let selectedText = terminalView.terminal.getSelectedText()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
    }
    
    @objc func paste() {
        if let string = NSPasteboard.general.string(forType: .string) {
            sendString(string)
        }
    }
}
