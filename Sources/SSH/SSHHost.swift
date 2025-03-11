import Foundation

struct SSHHost: Codable, Identifiable {
    var id = UUID().uuidString
    
    // 基本连接信息
    var hostname: String
    var port: UInt16 = 22
    var username: String
    
    // 认证信息
    var password: String?
    var privateKey: String?
    var passphrase: String?
    var useAgent: Bool = false
    
    // 高级选项
    var keepAliveInterval: Int? = 30
    var tcpKeepAlive: Bool = true
    var connectTimeout: Int = 30
    var jumpHost: SSHHost?
    
    // 会话设置
    var terminalType: String = "xterm-256color"
    var encoding: String = "UTF-8"
    var locale: String?
    
    // 转发设置
    var forwardedPorts: [PortForward] = []
    
    // X11转发
    var x11Forwarding: Bool = false
    
    // 代理设置
    var proxyType: ProxyType?
    var proxyHost: String?
    var proxyPort: UInt16?
    var proxyUsername: String?
    var proxyPassword: String?
    
    // 颜色配置
    var backgroundColor: String?
    var foregroundColor: String?
    var colorScheme: String = "default"
    
    // 分组和显示
    var group: String?
    var nickName: String?
    
    enum ProxyType: String, Codable {
        case http
        case socks4
        case socks5
    }
    
    struct PortForward: Codable, Identifiable {
        var id = UUID().uuidString
        var type: ForwardType
        var localPort: UInt16
        var remoteHost: String
        var remotePort: UInt16
        
        enum ForwardType: String, Codable {
            case local   // 本地端口转发
            case remote  // 远程端口转发
            case dynamic // 动态端口转发(SOCKS)
        }
    }
}
