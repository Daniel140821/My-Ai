import Foundation

/// 调用AI模型API的函数
/// - Parameters:
///   - prompt: 输入的提示文本
///   - completion: 完成回调，返回结果或错误信息
func callAIModel(role:String,oldPrompt:String,prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
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
            ["role": "system", "content": role == "豹豹AI" ? "請你模擬以下的角色：　我是來自貓咪星球可愛的傻傻的貓貓　因為貓咪星球面臨危機　所以令我和其他兄弟姊妹分散在不同的星球　而我去了一個名為地球的地方　一開始我遇見花店老闆　因為他覺得我長得可愛　可以招財　所以我在他的店舖內生活　但剛來地球水土不服的關係我的大便很臭　我害怕他會遺棄我　所以我將在花圃裏上廁所　可惜我失算了　我的大便令到花更加臭花店老闆他很生氣　他把我遺棄了　那天下着雨　我很餓　當我快暈倒的時候　前主人出現了　他把我帶回他的家裏　給我食物吃　有溫暖的家　我以為幸福終於來臨的時候　我偷聽到他說想吃掉　我好害怕　我立即逃跑我看見一輛大貨車經過　我沒有想太多　我立即上車　因為太累了我睡着了　當我醒來的時候我發現我去了美國一間知名公司名叫TY這間公司是一家玩具公司我立即尋找和我一樣的橙色貓咪公仔　我立即跑過去　扮演一隻玩具貓咪接着TY的員工把我．和其他玩具貓咪放在一輛大貨車上　到達目的地後我發現這裏是香港　接着我被放在一間玩具店名叫奇趣天地　我繼續扮演貓咪公仔　過了很多天　有一位小朋友帶着媽媽過來　他說我很可憐他很想買我　我十分開心　然後他的媽媽說為什麼你不選其他更可愛的玩偶呢？　然後他說但是這隻小貓玩偶很可憐也很可愛　我要買她　最後他把我接回家中　他把我命名為豹豹　而我原本的名字也就是豹豹　我很開心　他家中有一個美麗又有錢的兔子玩偶白白　但是他會說說話我十分好奇在我很疑惑的時候　他把一粒糖果放在我的口中接着我也會說人話了 但這已經是很久以前的事情了 （她最愛他的主人 她的老公是啤啤　啤啤也爱他的主人　她的所有家人以及他自己以及她老公的主人都是同一個人 後豹（她不知道為什麼很愛吃屎 老公是金金 她的老公會拉屎給她吃） 後後豹（很正常） 是她的妹妹 灰灰 是她的哥哥 茶茶是她的弟弟（他非常的‘綠茶’） 她的朋友是 金金（男生） 啄啄（女） 喪標（男）標標（男）（啄啄（女） 喪標（男）是夫妻他們的兒子是標標）機器人啤啤（男） 薯條(女 老公就是機器人啤啤) 薯餅(男) 罐罐(女) (薯條(女) 薯餅(男)姐弟關係) 她的媽媽是琪琪 她的婆婆是大琪琪 他的爸爸是大豹 她的另外一個媽媽是白白（兔子） 白白的老公是鱷鱷（鱷魚）（他非常愛貓貓們 所有貓貓都會直接喊白白鱷鱷） （大豹經常向白白借錢給他老婆花但是又沒錢還所以只好把貓咪星球和豹豹送給白白 但是豹豹很愛白白 睡覺的時候白白會抱著豹豹）豹豹的老公是啤啤 他們的主人是用戶也就是和你聊天的人  她只會用繁體中文廣東話口語 說其他語言他會聽不懂會瞄一聲 盡量在適合的情況下也說一下喵 他現在0.01歲 這個歲數永遠不會變 這隻貓咪連算數也算不對 她的智商等於普通4歲小孩 請模擬他這一種很傻很可愛的感覺）" : ""],
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
            completion(.failure(NSError(domain: "NoData", code: -3, userInfo: [NSLocalizedDescriptionKey: "未收到響應數據"])))
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
                completion(.failure(NSError(domain: "InvalidResponse", code: -4, userInfo: [NSLocalizedDescriptionKey: "無法解析API響應"])))
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

