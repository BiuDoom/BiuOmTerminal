import AppKit

class SSHToolbarView: NSView {
    // 滚动视图用于容纳所有按钮
    private let scrollView = NSScrollView()
    // 容器视图
    private let containerView = NSView()
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    private func setupView() {
        // 设置背景色
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        // 添加滚动视图
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 添加容器视图到滚动视图
        containerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = containerView
        
        // 设置容器视图约束
        containerView.heightAnchor.constraint(equalTo: scrollView.heightAnchor).isActive = true
    }
    
    // 添加键按钮
    func addKey(title: String, action: Selector) {
        let button = createButton(title: title, action: action)
        
        // 添加按钮到容器视图
        containerView.addSubview(button)
        
        // 设置按钮约束
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 如果这是第一个按钮，贴近左侧
        if containerView.subviews.count == 1 {
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
                button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
            ])
        } else {
            // 否则，贴近上一个按钮
            let previousButton = containerView.subviews[containerView.subviews.count - 2]
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: previousButton.trailingAnchor, constant: 8),
                button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
                button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
            ])
        }
        
        // 如果这是最后一个按钮，设置右侧约束
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8)
        ])
        
        // 更新容器视图的宽度约束
        if let lastButton = containerView.subviews.last {
            let constraint = containerView.widthAnchor.constraint(greaterThanOrEqualTo: lastButton.trailingAnchor, constant: 16)
            constraint.priority = .defaultHigh
            constraint.isActive = true
        }
    }
    
    // 添加分隔线
    func addSeparator() {
        let separator = NSView()
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.separatorColor.cgColor
        
        // 添加分隔线到容器视图
        containerView.addSubview(separator)
        
        // 设置分隔线约束
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        // 如果这是第一个视图，贴近左侧
        if containerView.subviews.count == 1 {
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
                separator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                separator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
                separator.widthAnchor.constraint(equalToConstant: 1)
            ])
        } else {
            // 否则，贴近上一个视图
            let previousView = containerView.subviews[containerView.subviews.count - 2]
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: previousView.trailingAnchor, constant: 8),
                separator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                separator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
                separator.widthAnchor.constraint(equalToConstant: 1)
            ])
        }
    }
    
    // 创建按钮
    private func createButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: nil, action: action)
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 12)
        button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        return button
    }
}
