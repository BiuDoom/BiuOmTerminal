import Foundation
import Shout
import Dispatch

class SSHManager {
    // 单例模式
    static let shared = SSHManager()
    
    // 活动会话
    private var activeSessions: [String: SSHSession] = [:]
    
    // 会话状态回调
    typealias SessionStatusCallback = (String, SessionStatus) -> Void
    private var statusCallbacks: [String: SessionStatusCallback] = [:]
    
    enum SessionStatus {
        case connecting
        case connected
        case disconnected
        case error(Error)
    }
    
    // 私有初始化方法
    private init() {}
    
    // 创建并连接新会话
    func connect(host: SSHHost, completion: @escaping (Result<SSHSession, Error>) -> Void) {
        let sessionID = UUID().uuidString
        
        // 如果配置了JumpHost，先创建跳板机连接
        if let jumpHost = host.jumpHost {
            setupJumpHostConnection(jumpHost: jumpHost, targetHost: host) { result in
                switch result {
                case .success(let session):
                    self.activeSessions[sessionID] = session
                    completion(.success(session))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        // 创建SSH会话
        let ssh = try! SSH()
        
        // 设置连接超时
        ssh.timeout = host.connectTimeout
        
        // 处理主机密钥验证
        ssh.verifyHost = false // 在生产环境中应更改为true并正确处理主机密钥验证
        
        do {
            // 连接到服务器
            try ssh.connect(host: host.hostname, port: Int(host.port))
            
            // 进行身份验证
            try authenticate(ssh: ssh, host: host)
            
            // 创建会话对象
            let session = SSHSession(id: sessionID, ssh: ssh, host: host)
            
            // 存储会话
            activeSessions[sessionID] = session
            
            // 成功回调
            completion(.success(session))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 认证方法
    private func authenticate(ssh: SSH, host: SSHHost) throws {
        // 尝试使用私钥认证
        if let privateKey = host.privateKey, !privateKey.isEmpty {
            // 将私钥保存到临时文件
            let tempDir = NSTemporaryDirectory()
            let keyPath = tempDir + "/temp_key_\(UUID().uuidString)"
            try privateKey.write(toFile: keyPath, atomically: true, encoding: .utf8)
            defer {
                // 删除临时私钥文件
                try? FileManager.default.removeItem(atPath: keyPath)
            }
            
            // 使用私钥认证
            if let passphrase = host.passphrase, !passphrase.isEmpty {
                try ssh.authenticate(username: host.username, privateKey: keyPath, passphrase: passphrase)
            } else {
                try ssh.authenticate(username: host.username, privateKey: keyPath)
            }
        }
        // 尝试使用密码认证
        else if let password = host.password, !password.isEmpty {
            try ssh.authenticate(username: host.username, password: password)
        }
        // 尝试使用SSH代理认证
        else if host.useAgent {
            try ssh.authenticateByAgent(username: host.username)
        } else {
            throw NSError(domain: "SSHManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No authentication method provided"])
        }
    }
    
    // 处理跳板机连接
    private func setupJumpHostConnection(jumpHost: SSHHost, targetHost: SSHHost, completion: @escaping (Result<SSHSession, Error>) -> Void) {
        // 先连接到跳板机
        let ssh = try! SSH()
        ssh.timeout = jumpHost.connectTimeout
        ssh.verifyHost = false
        
        do {
            // 连接到跳板机
            try ssh.connect(host: jumpHost.hostname, port: Int(jumpHost.port))
            try authenticate(ssh: ssh, host: jumpHost)
            
            // 设置本地端口转发
            let localPort = getAvailableLocalPort()
            try ssh.portForwardLocal(from: UInt(localPort), to: targetHost.hostname, port: UInt(targetHost.port))
            
            // 创建到转发端口的本地连接
            let targetSSH = try! SSH()
            targetSSH.timeout = targetHost.connectTimeout
            targetSSH.verifyHost = false
            
            try targetSSH.connect(host: "localhost", port: localPort)
            try authenticate(ssh: targetSSH, host: targetHost)
            
            // 创建并存储会话
            let sessionID = UUID().uuidString
            let session = SSHSession(id: sessionID, ssh: targetSSH, host: targetHost, jumpSSH: ssh)
            activeSessions[sessionID] = session
            
            completion(.success(session))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 获取可用的本地端口
    private func getAvailableLocalPort() -> Int {
        // 简单实现，可以改进为动态检测可用端口
        return Int.random(in: 10000...65000)
    }
    
    // 关闭会话
    func disconnect(sessionID: String) {
        if let session = activeSessions[sessionID] {
            session.disconnect()
            activeSessions.removeValue(forKey: sessionID)
        }
    }
    
    // 获取活动会话
    func getSession(sessionID: String) -> SSHSession? {
        return activeSessions[sessionID]
    }
    
    // 执行命令
    func executeCommand(sessionID: String, command: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let session = activeSessions[sessionID] else {
            completion(.failure(NSError(domain: "SSHManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Session not found or not connected"])))
            return
        }
        
        do {
            let output = try session.ssh.capture(command)
            completion(.success(output))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 设置端口转发
    func setupPortForwarding(sessionID: String, localPort: Int, remoteHost: String, remotePort: Int) -> Result<Void, Error> {
        guard let session = activeSessions[sessionID] else {
            return .failure(NSError(domain: "SSHManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "Session not found or not connected"]))
        }
        
        do {
            try session.ssh.portForwardLocal(from: UInt(localPort), to: remoteHost, port: UInt(remotePort))
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // 创建SFTP会话
    func createSFTPSession(sessionID: String) -> Result<SFTP, Error> {
        guard let session = activeSessions[sessionID] else {
            return .failure(NSError(domain: "SSHManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Session not found or not connected"]))
        }
        
        do {
            let sftp = try session.ssh.openSftp()
            return .success(sftp)
        } catch {
            return .failure(error)
        }
    }
}

// SSH会话类
class SSHSession {
    let id: String
    let ssh: SSH
    let host: SSHHost
    var jumpSSH: SSH?
    
    init(id: String, ssh: SSH, host: SSHHost, jumpSSH: SSH? = nil) {
        self.id = id
        self.ssh = ssh
        self.host = host
        self.jumpSSH = jumpSSH
    }
    
    var identifier: String {
        return id
    }
    
    var isConnected: Bool {
        // Shout没有直接的isConnected属性，这里简单返回true
        // 实际使用中可能需要更健壮的实现
        return true
    }
    
    func disconnect() {
        ssh.close()
        jumpSSH?.close()
    }
    
    // 创建交互式Shell会话
    func createShellSession() -> ShellSession? {
        do {
            return try ssh.openShell()
        } catch {
            print("Error creating shell session: \(error)")
            return nil
        }
    }
}
