import AppKit

class SSHSettingsController: NSViewController {
    // 主机配置
    var host: SSHHost?
    // 完成回调
    var completion: ((SSHHost?) -> Void)?
    
    // UI组件
    private let scrollView = NSScrollView()
    private let containerView = NSView()
    
    // 基本信息字段
    private let nicknameTextField = NSTextField()
    private let hostnameTextField = NSTextField()
    private let portTextField = NSTextField()
    private let usernameTextField = NSTextField()
    
    // 认证选项
    private let authSegmentedControl = NSSegmentedControl()
    private let passwordTextField = NSSecureTextField()
    private let privateKeyTextView = NSTextView()
    private let passphraseTextField = NSSecureTextField()
    private let browseKeyButton = NSButton()
    
    // 高级选项
    private let advancedOptionsButton = NSButton()
    private let advancedOptionsView = NSView()
    private var advancedOptionsViewHeightConstraint: NSLayoutConstraint?
    private var isAdvancedOptionsExpanded = false
    
    // 分组选择
    private let groupTextField = NSTextField()
    
    // 颜色主题选择
    private let themeLabel = NSTextField()
    private let themePicker = NSPopUpButton()
    private var themes: [String] = []
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 700))
        view.wantsLayer = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图
        view.wantsLayer = true
        title = host == nil ? "新建SSH连接" : "编辑SSH连接"
        
        // 设置导航栏按钮
        setupNavigationButtons()
        
        // 加载所有主题
        loadThemes()
        
        // 设置UI
        setupUI()
        
        // 如果是编辑现有主机，填充表单
        if let host = host {
            fillFormWithHost(host)
        }
    }
    
    private func setupNavigationButtons() {
        // macOS通常使用窗口按钮而不是导航栏按钮
        // 我们可以添加工具栏项或窗口按钮
        
        // 取消按钮
        let cancelButton = NSButton(title: "取消", target: self, action: #selector(cancelTapped))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)
        
        // 保存按钮
        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveTapped))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        // 设置按钮约束
        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupUI() {
        // 设置滚动视图
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50) // 留出底部按钮空间
        ])
        
        // 设置容器视图
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = containerView
        
        // containerView 需要匹配滚动视图的宽度
        containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        
        // 设置表单元素
        setupFormFields()
    }
    
    private func setupFormFields() {
        let margin: CGFloat = 16
        let spacing: CGFloat = 8
        
        // 昵称
        let nicknameLabel = createLabel("昵称")
        setupTextField(nicknameTextField, placeholder: "可选")
        
        // 主机名
        let hostnameLabel = createLabel("主机名")
        setupTextField(hostnameTextField, placeholder: "example.com 或 192.168.1.1")
        
        // 端口
        let portLabel = createLabel("端口")
        setupTextField(portTextField, placeholder: "22")
        
        // 用户名
        let usernameLabel = createLabel("用户名")
        setupTextField(usernameTextField, placeholder: "用户名")
        
        // 认证方式
        let authLabel = createLabel("认证方式")
        authSegmentedControl.segmentCount = 3
        authSegmentedControl.setLabel("密码", forSegment: 0)
        authSegmentedControl.setLabel("私钥", forSegment: 1)
        authSegmentedControl.setLabel("SSH代理", forSegment: 2)
        authSegmentedControl.target = self
        authSegmentedControl.action = #selector(authMethodChanged)
        
        // 密码输入框
        setupSecureTextField(passwordTextField, placeholder: "密码")
        
        // 私钥输入区
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .bezelBorder
        
        privateKeyTextView.font = NSFont.systemFont(ofSize: 12)
        privateKeyTextView.isEditable = true
        privateKeyTextView.isSelectable = true
        privateKeyTextView.isRichText = false
        scrollView.documentView = privateKeyTextView
        
        // 私钥密码
        setupSecureTextField(passphraseTextField, placeholder: "密钥密码（可选）")
        
        // 浏览密钥按钮
        browseKeyButton.title = "选择密钥文件"
        browseKeyButton.bezelStyle = .rounded
        browseKeyButton.target = self
        browseKeyButton.action = #selector(browseKeyTapped)
        
        // 高级选项按钮
        advancedOptionsButton.title = "高级选项"
        advancedOptionsButton.bezelStyle = .rounded
        advancedOptionsButton.target = self
        advancedOptionsButton.action = #selector(toggleAdvancedOptions)
        
        // 高级选项视图
        advancedOptionsView.wantsLayer = true
        advancedOptionsView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        advancedOptionsView.layer?.cornerRadius = 4
        advancedOptionsView.isHidden = true
        
        // 分组
        let groupLabel = createLabel("分组")
        setupTextField(groupTextField, placeholder: "可选")
        
        // 主题
        themeLabel.stringValue = "颜色主题"
        themeLabel.isBezeled = false
        themeLabel.isEditable = false
        themeLabel.drawsBackground = false
        
        themePicker.target = self
        themePicker.action = #selector(themeSelected)
        // 填充主题下拉菜单
        for theme in themes {
            themePicker.addItem(withTitle: theme)
        }
        
        // 将元素添加到容器
        containerView.addSubview(nicknameLabel)
        containerView.addSubview(nicknameTextField)
        containerView.addSubview(hostnameLabel)
        containerView.addSubview(hostnameTextField)
        containerView.addSubview(portLabel)
        containerView.addSubview(portTextField)
        containerView.addSubview(usernameLabel)
        containerView.addSubview(usernameTextField)
        containerView.addSubview(authLabel)
        containerView.addSubview(authSegmentedControl)
        containerView.addSubview(passwordTextField)
        containerView.addSubview(scrollView)
        containerView.addSubview(passphraseTextField)
        containerView.addSubview(browseKeyButton)
        containerView.addSubview(advancedOptionsButton)
        containerView.addSubview(advancedOptionsView)
        containerView.addSubview(groupLabel)
        containerView.addSubview(groupTextField)
        containerView.addSubview(themeLabel)
        containerView.addSubview(themePicker)
        
        // 设置自动布局约束
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        nicknameTextField.translatesAutoresizingMaskIntoConstraints = false
        hostnameLabel.translatesAutoresizingMaskIntoConstraints = false
        hostnameTextField.translatesAutoresizingMaskIntoConstraints = false
        portLabel.translatesAutoresizingMaskIntoConstraints = false
        portTextField.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false
        authLabel.translatesAutoresizingMaskIntoConstraints = false
        authSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        passphraseTextField.translatesAutoresizingMaskIntoConstraints = false
        browseKeyButton.translatesAutoresizingMaskIntoConstraints = false
        advancedOptionsButton.translatesAutoresizingMaskIntoConstraints = false
        advancedOptionsView.translatesAutoresizingMaskIntoConstraints = false
        groupLabel.translatesAutoresizingMaskIntoConstraints = false
        groupTextField.translatesAutoresizingMaskIntoConstraints = false
        themeLabel.translatesAutoresizingMaskIntoConstraints = false
        themePicker.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置约束
        // ... 约束代码与iOS版类似，但使用NSLayoutConstraint ...
        
        // 这里是简化版本
        NSLayoutConstraint.activate([
            // 昵称
            nicknameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin),
            nicknameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            nicknameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            
            nicknameTextField.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: spacing),
            nicknameTextField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            nicknameTextField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            
            // 主机名
            hostnameLabel.topAnchor.constraint(equalTo: nicknameTextField.bottomAnchor, constant: margin),
            // ... 其他约束
        ])
        
        // 设置高级选项视图的高度约束
        advancedOptionsViewHeightConstraint = advancedOptionsView.heightAnchor.constraint(equalToConstant: 0)
        advancedOptionsViewHeightConstraint?.isActive = true
        
        // 配置高级选项视图内容
        setupAdvancedOptionsView()
        
        // 初始化UI状态
        authSegmentedControl.selectedSegment = 0
        updateAuthUI()
    }
    
    // ... 更多方法转换 ...
    
    @objc private func saveTapped() {
        // 验证表单
        guard let hostname = hostnameTextField.stringValue, !hostname.isEmpty,
              let username = usernameTextField.stringValue, !username.isEmpty,
              let portText = portTextField.stringValue, let port = UInt16(portText) else {
            showAlert(title: "输入错误", message: "请填写必要的连接信息")
            return
        }
        
        // 创建或更新主机对象
        var host = self.host ?? SSHHost(hostname: hostname, username: username)
        
        // 设置基本属性
        host.hostname = hostname
        host.username = username
        host.port = port
        host.nickName = nicknameTextField.stringValue
        host.group = groupTextField.stringValue
        
        // 设置认证信息
        switch authSegmentedControl.selectedSegment {
        case 0: // 密码
            host.password = passwordTextField.stringValue
            host.privateKey = nil
            host.passphrase = nil
            host.useAgent = false
        case 1: // 私钥
            host.password = nil
            host.privateKey = privateKeyTextView.string
            host.passphrase = passphraseTextField.stringValue
            host.useAgent = false
        case 2: // SSH代理
            host.password = nil
            host.privateKey = nil
            host.passphrase = nil
            host.useAgent = true
        default:
            break
        }
        
        // 设置主题
        host.colorScheme = themes[themePicker.indexOfSelectedItem]
        
        // 保存密码到钥匙串
        if let password = host.password, !password.isEmpty {
            _ = SSHCredentialManager.shared.savePassword(password, forHost: host.hostname, username: host.username)
            // 清除密码，不存储在主机配置中
            host.password = nil
        }
        
        // 返回创建/编辑的主机对象
        completion?(host)
        view.window?.close()
    }
    
    @objc private func cancelTapped() {
        view.window?.close()
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
    
    // 辅助方法
    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField()
        label.stringValue = text
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.font = NSFont.systemFont(ofSize: 12)
        return label
    }
    
    private func setupTextField(_ textField: NSTextField, placeholder: String) {
        textField.placeholderString = placeholder
        textField.font = NSFont.systemFont(ofSize: 12)
    }
    
    private func setupSecureTextField(_ textField: NSSecureTextField, placeholder: String) {
        textField.placeholderString = placeholder
        textField.font = NSFont.systemFont(ofSize: 12)
    }
    
    // 其他方法转换...
}
