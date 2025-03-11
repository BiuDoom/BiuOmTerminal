import Foundation

class SSHHostsManager {
    // 单例模式
    static let shared = SSHHostsManager()
    
    // 主机列表
    private(set) var hosts: [SSHHost] = []
    
    // 文件URL
    private let fileURL: URL
    
    // 初始化
    private init() {
        // 获取文档目录
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documentDirectory.appendingPathComponent("ssh_hosts.json")
        
        // 加载保存的主机
        loadHosts()
    }
    
    // 加载主机列表
    private func loadHosts() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            hosts = try decoder.decode([SSHHost].self, from: data)
        } catch {
            print("Error loading SSH hosts: \(error)")
        }
    }
    
    // 保存主机列表
    private func saveHosts() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(hosts)
            try data.write(to: fileURL)
        } catch {
            print("Error saving SSH hosts: \(error)")
        }
    }
    
    // 添加主机
    @discardableResult
    func addHost(_ host: SSHHost) -> Bool {
        // 生成新ID，确保唯一性
        var newHost = host
        newHost.id = UUID().uuidString
        
        hosts.append(newHost)
        saveHosts()
        return true
    }
    
    // 更新主机
    @discardableResult
    func updateHost(_ host: SSHHost) -> Bool {
        guard let index = hosts.firstIndex(where: { $0.id == host.id }) else {
            return false
        }
        
        hosts[index] = host
        saveHosts()
        return true
    }
    
    // 删除主机
    @discardableResult
    func deleteHost(withID id: String) -> Bool {
        guard let index = hosts.firstIndex(where: { $0.id == id }) else {
            return false
        }
        
        hosts.remove(at: index)
        saveHosts()
        return true
    }
    
    // 按组获取主机
    func hostsGrouped() -> [String: [SSHHost]] {
        var groupedHosts: [String: [SSHHost]] = [:]
        
        for host in hosts {
            let group = host.group ?? "未分组"
            if groupedHosts[group] == nil {
                groupedHosts[group] = []
            }
            groupedHosts[group]?.append(host)
        }
        
        return groupedHosts
    }
    
    // 按ID获取主机
    func getHost(withID id: String) -> SSHHost? {
        return hosts.first(where: { $0.id == id })
    }
    
    // 导入配置
    func importFromFile(url: URL) -> (imported: Int, failed: Int) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedHosts = try decoder.decode([SSHHost].self, from: data)
            
            var imported = 0
            var failed = 0
            
            for host in importedHosts {
                var newHost = host
                newHost.id = UUID().uuidString // 确保ID唯一
                
                if !hosts.contains(where: {
                    $0.hostname == host.hostname &&
                    $0.port == host.port &&
                    $0.username == host.username
                }) {
                    hosts.append(newHost)
                    imported += 1
                } else {
                    failed += 1
                }
            }
            
            if imported > 0 {
                saveHosts()
            }
            
            return (imported, failed)
        } catch {
            print("Error importing hosts: \(error)")
            return (0, 0)
        }
    }
    
    // 导出配置
    func exportToFile(url: URL) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(hosts)
            try data.write(to: url)
            return true
        } catch {
            print("Error exporting hosts: \(error)")
            return false
        }
    }
    
    // 从macOS的~/.ssh/config导入配置
    func importFromSSHConfig() -> (imported: Int, failed: Int) {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configURL = homeDir.appendingPathComponent(".ssh/config")
        
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return (0, 0)
        }
        
        do {
            let configContent = try String(contentsOf: configURL, encoding: .utf8)
            return parseSSHConfig(configContent)
        } catch {
            print("Error reading SSH config: \(error)")
            return (0, 0)
        }
    }
    
    // 解析SSH配置文件
    private func parseSSHConfig(_ config: String) -> (imported: Int, failed: Int) {
        var imported = 0
        var failed = 0
        
        var currentHost: SSHHost?
        var currentHostName: String?
        
        let lines = config.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 跳过空行和注释
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // 分割键值对
            let components = trimmed.components(separatedBy: .whitespaces)
            guard components.count >= 2 else { continue }
            
            let key = components[0].lowercased()
            let value = components.dropFirst().joined(separator: " ")
            
            if key == "host" {
                // 当找到新的Host条目时，保存之前的主机（如果有）
                if let host = currentHost, let hostName = currentHostName {
                    host.hostname = hostName
                    if !hosts.contains(where: {
                        $0.hostname == host.hostname &&
                        $0.port == host.port &&
                        $0.username == host.username
                    }) {
                        hosts.append(host)
                        imported += 1
                    } else {
                        failed += 1
                    }
                }
                
                // 创建新的主机条目
                currentHost = SSHHost(hostname: "", username: "")
                currentHost?.id = UUID().uuidString
                currentHost?.nickName = value
                currentHostName = nil
            } else if let host = currentHost {
                // 配置当前主机的属性
                switch key {
                case "hostname":
                    currentHostName = value
                case "user", "username":
                    host.username = value
                case "port":
                    if let port = UInt16(value) {
                        host.port = port
                    }
                case "identityfile":
                    let keyPath = value.replacingOccurrences(of: "~", with: FileManager.default.homeDirectoryForCurrentUser.path)
                    do {
                        host.privateKey = try String(contentsOfFile: keyPath, encoding: .utf8)
                    } catch {
                        print("Error reading identity file: \(error)")
                    }
                case "serveraliveinterval":
                    if let interval = Int(value) {
                        host.keepAliveInterval = interval
                    }
                default:
                    break
                }
            }
        }
        
        // 保存最后一个主机（如果有）
        if let host = currentHost, let hostName = currentHostName {
            host.hostname = hostName
            if !hosts.contains(where: {
                $0.hostname == host.hostname &&
                $0.port == host.port &&
                $0.username == host.username
            }) {
                hosts.append(host)
                imported += 1
            } else {
                failed += 1
            }
        }
        
        if imported > 0 {
            saveHosts()
        }
        
        return (imported, failed)
    }
}
