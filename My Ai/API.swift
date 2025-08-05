import Foundation

/// 调用AI模型API的函数
/// - Parameters:
///   - prompt: 输入的提示文本
///   - completion: 完成回调，返回结果或错误信息
func callAIModel(oldPrompt:String,prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
    // API端点URL - 根据实际文档替换
    guard let url = URL(string: "https://open.bigmodel.cn/api/paas/v4/chat/completions") else {
        completion(.failure(NSError(domain: "InvalidURL", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的API URL"])))
        return
    }
    
    // 配置请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    // 写死的API Key
    request.addValue("Bearer cdddd1c8f1c44a9c849ac6654fff9730.KmEdRZp7qb2QgT5D", forHTTPHeaderField: "Authorization")
    
    // 构建请求体
    let requestBody: [String: Any] = [
        "model": "glm-4.5-flash",  // 替换为实际模型名称
        "messages": [
            ["role": "system", "content": oldPrompt],
            ["role": "user", "content": prompt]
        ]
    ]
    
    // 转换为JSON数据
    guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
        completion(.failure(NSError(domain: "InvalidJSON", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法构建请求JSON"])))
        return
    }
    
    request.httpBody = jsonData
    
    // 发起请求
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "NoData", code: -3, userInfo: [NSLocalizedDescriptionKey: "未收到响应数据"])))
            return
        }
        
        // 解析JSON响应
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(.success(content))
            } else {
                completion(.failure(NSError(domain: "InvalidResponse", code: -4, userInfo: [NSLocalizedDescriptionKey: "无法解析API响应"])))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    task.resume()
}

// 使用示例
//callAIModel(oldPrompt:"",prompt: "你好，能帮我解释一下这个API吗？") { result in
//    switch result {
//    case .success(let response):
//        print("AI响应: \(response)")
//    case .failure(let error):
//        print("发生错误: \(error.localizedDescription)")
//    }
//}

