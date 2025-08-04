import Foundation
import Network

// 线程安全的原子属性包装器
@propertyWrapper
struct Atomic<T> {
    private let queue = DispatchQueue(label: "Atomic.Queue")
    private var value: T
    
    init(wrappedValue: T) {
        self.value = wrappedValue
    }
    
    var wrappedValue: T {
        get { queue.sync { value } }
        set { queue.sync { value = newValue } }
    }
}

// 网络监控器（线程安全版）
final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "OpenRouter.NetworkMonitor")
    
    // 使用原子属性确保线程安全
    @Atomic private(set) var isConnected = false
    
    private init() {
        monitor = NWPathMonitor()
        // 初始化时立即获取当前网络状态
        monitor.pathUpdateHandler = { [weak self] path in
            self?.isConnected = path.status == .satisfied
            print("网络状态更新: \(self?.isConnected == true ? "已连接" : "未连接")")
        }
        monitor.start(queue: queue)
        
        // 强制立即检查一次网络状态
        monitor.pathUpdateHandler?(monitor.currentPath)
    }
    
    // 主动检查网络状态（带短暂延迟确保准确性）
    func checkConnection(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            completion(self.isConnected)
        }
    }
}

// API 错误类型
enum OpenRouterError: LocalizedError {
    case noNetwork
    case invalidURL
    case invalidJSON
    case invalidResponse
    case noData
    case parsingError
    case apiError(code: Int, message: String, rawResponse: String)
    case networkError(Error)
    case emptyPrompt  // 输入为空错误
    
    var errorDescription: String? {
        switch self {
        case .noNetwork: return "无网络连接，请检查网络设置"
        case .invalidURL: return "API地址无效"
        case .invalidJSON: return "请求数据格式错误"
        case .invalidResponse: return "服务器响应格式错误"
        case .noData: return "服务器未返回数据"
        case .parsingError: return "响应数据解析失败"
        case .apiError(_, let message, _): return message
        case .networkError(let error): return error.localizedDescription
        case .emptyPrompt: return "输入内容不能为空，请输入问题或提示"
        }
    }
    
    var rawResponse: String? {
        if case .apiError(_, _, let rawResponse) = self { return rawResponse }
        return nil
    }
}

// 修复输入验证问题的OpenRouter API客户端
final class OpenRouterClient {
    static let shared = OpenRouterClient()
    private init() {}
    
    private let apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    private let fixedModel = "google/gemma-3-27b-it:free"
    private let timeoutInterval: TimeInterval = 30
    
    func sendRequest(
        prompt: String,
        apiKey: String,
        completion: @escaping (Result<String, OpenRouterError>) -> Void
    ) {
        // 1. 改进的输入验证 - 更宽松且带有调试信息
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 调试信息：输出原始长度和处理后的长度
        print("原始输入长度: \(prompt.count), 处理后长度: \(trimmedPrompt.count)")
        
        // 允许至少包含一个可见字符的输入
        guard trimmedPrompt.count > 0 else {
            completion(.failure(.emptyPrompt))
            return
        }
        
        // 2. 检查网络状态
        NetworkMonitor.shared.checkConnection { isConnected in
            guard isConnected else {
                completion(.failure(.noNetwork))
                return
            }
            
            // 3. 验证URL
            guard let url = URL(string: self.apiEndpoint) else {
                completion(.failure(.invalidURL))
                return
            }
            
            // 4. 构建请求体（使用处理后的输入）
            let requestBody: [String: Any] = [
                "model": self.fixedModel,
                "messages": [["role": "user", "content": trimmedPrompt]]
            ]
            
            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
                completion(.failure(.invalidJSON))
                return
            }
            
            // 5. 配置请求
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            request.timeoutInterval = self.timeoutInterval
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(apiKey.trimmingCharacters(in: .whitespaces))", forHTTPHeaderField: "Authorization")
            
            // 6. 发起请求
            print("发起请求时网络状态: 已连接")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                self.handleResponse(data: data, response: response, error: error, completion: completion)
            }
            task.resume()
        }
    }
    
    private func handleResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completion: @escaping (Result<String, OpenRouterError>) -> Void
    ) {
        if let error = error {
            print("网络请求错误: \(error.localizedDescription)")
            completion(.failure(.networkError(error)))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(.invalidResponse))
            return
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let rawResponse = data.flatMap { String(data: $0, encoding: .utf8) } ?? "无数据"
            let message = self.getErrorMessage(for: httpResponse.statusCode, rawResponse: rawResponse)
            completion(.failure(.apiError(code: httpResponse.statusCode, message: message, rawResponse: rawResponse)))
            return
        }
        
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(.success(content))
            } else {
                completion(.failure(.parsingError))
            }
        } catch {
            completion(.failure(.parsingError))
        }
    }
    
    // 改进错误信息，直接使用API返回的错误信息
    private func getErrorMessage(for statusCode: Int, rawResponse: String) -> String {
        // 尝试从原始响应中提取API返回的错误信息
        if let data = rawResponse.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        
        // 若无法提取，使用默认信息
        switch statusCode {
        case 401: return "认证失败，请检查API密钥"
        case 403: return "权限不足，无法访问模型"
        case 404: return "请求地址不存在"
        case 429: return "请求过于频繁，请稍后再试"
        case 500...599: return "服务器错误 (状态码: \(statusCode))"
        default: return "请求失败 (状态码: \(statusCode))"
        }
    }
}
