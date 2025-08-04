//
//  ContentView.swift
//  My Ai
//
//  Created by Daniel on 3/8/2025.
//

import SwiftUI

struct ContentView: View {
    let apiKey = "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"
    
    @State private var question: String = ""
    
    @State private var ChatContent : [String] = []
    
    var body: some View {
        ScrollView(.vertical){
            if ChatContent != []{
                VStack{
                    ForEach(0..<ChatContent.count, id: \.self) { index in
                        Text(ChatContent[index])
                            .padding()
                            .foregroundColor(.white)
                    }.background{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue.gradient)
                    }
                }.padding()
            }
        }
        
        Spacer()
        
        VStack {
            TextField("你想問什麼？",text: $question)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .padding(.horizontal)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.infinity)
                .onSubmit {
                    print(question)
                    
                    ChatContent.append(question)
                    
                    print("loading")
                    
                    ChatContent.append("思考中...")
                    // 使用示例（修正错误处理）
                    OpenRouterClient.shared.sendRequest(prompt: question, apiKey: apiKey) { result in
                        switch result {
                        case .success(let response):
                            print("成功：\(response)")
                            ChatContent[ChatContent.count - 1] = response
                        case .failure(let error):
                            print("错误：\(error.localizedDescription)")
                        }
                    }
                    
                    question = ""

                }
        }.padding()
        
        
        
    }
}

#Preview {
    ContentView()
}
