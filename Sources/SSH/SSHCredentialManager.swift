import Foundation
import Security

class SSHCredentialManager {
    // 单例模式
    static let shared = SSHCredentialManager()
    
    // 服务名称，用于标识Keychain条目
    private let serviceName = "com.biudoom.biuomterminus"
    
    private init() {}
    
    // 保存密码
    func savePassword(_ password: String, forHost host: String, username: String) -> Bool {
        let account = "\(username)@\(host)"
        
        // 准备要保存的数据
        guard let passwordData = password.data(using: .utf8) else {
            return false
        }
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // 尝试添加密码到Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // 如果密码已存在，尝试更新
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: passwordData
            ]
            
            return SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary) == errSecSuccess
        }
        
        return status == errSecSuccess
    }
    
    // 获取密码
    func getPassword(forHost host: String, username: String) -> String? {
        let account = "\(username)@\(host)"
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // 从Keychain获取密码
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let passwordData = item as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    // 删除密码
    func deletePassword(forHost host: String, username: String) -> Bool {
        let account = "\(username)@\(host)"
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        // 从Keychain删除密码
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
    
    // 保存密钥
    func savePrivateKey(_ privateKey: String, forHost host: String, username: String) -> Bool {
        let account = "key-\(username)@\(host)"
        
        // 准备要保存的数据
        guard let keyData = privateKey.data(using: .utf8) else {
            return false
        }
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // 尝试添加密钥到Keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // 如果密钥已存在，尝试更新
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: keyData
            ]
            
            return SecItemUpdate(updateQuery as CFDictionary, attributesToUpdate as CFDictionary) == errSecSuccess
        }
        
        return status == errSecSuccess
    }
    
    // 获取密钥
    func getPrivateKey(forHost host: String, username: String) -> String? {
        let account = "key-\(username)@\(host)"
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        // 从Keychain获取密钥
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let keyData = item as? Data,
              let key = String(data: keyData, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    // 删除密钥
    func deletePrivateKey(forHost host: String, username: String) -> Bool {
        let account = "key-\(username)@\(host)"
        
        // 创建查询字典
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        // 从Keychain删除密钥
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
