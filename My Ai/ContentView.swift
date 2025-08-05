//
//  ContentView.swift
//  My Ai
//
//  Created by Daniel on 3/8/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var question: String = ""
    
    @State private var ChatContent : [String] = []
    
    @State private var AIModel : String = "智普AI GLM 4.5 Flash"
    
    var body: some View {
        HStack{
            
            Menu(AIModel) {
                
                Button {
                    AIModel = "智普AI GLM 4.5 Flash"
                } label: {
                    Label {
                        Text("智普AI GLM 4.5 Flash")
                    } icon: {
                        if AIModel == "智普AI GLM 4.5 Flash"{
                            Image(systemName: "checkmark")
                        }
                    }

                }
                
                Button {
                    AIModel = "豹豹AI"
                } label: {
                    Label {
                        Text("豹豹AI")
                    } icon: {
                        if AIModel == "豹豹AI"{
                            Image(systemName: "checkmark")
                        }
                    }

                }
                
            }
            .foregroundColor(Color(.label))
            .font(.title2.bold())
            .padding()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
                
            
            Spacer()
            
            Image(systemName: "eraser.fill")
                .font(.title2.bold())
                .padding()
                .onTapGesture {
                    ChatContent = []
                }
                
        }
        .background(Color(.secondarySystemBackground))
        
        GeometryReader{Proxy in
            ScrollView(.vertical){
                if ChatContent != []{
                    VStack{
                        
                        ForEach(0..<ChatContent.count, id: \.self) { index in
                            
                            var isAI: Bool {
                                return ChatContent[index].contains("<aiIdentifierForAPP?>")
                            }
                            
                            VStack{
                                
                                Text(removeIdentifier(str:ChatContent[index]))
                                    .padding()
                                    .foregroundColor(.white)
                                    .textSelection(.enabled)
                                    .background{
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(isAI ? Color(.systemGray2).gradient : Color(.blue).gradient)
                                    }
                            }
                            .frame(maxWidth: .infinity, alignment: isAI ? .leading : .trailing)
                        }
                        
                    }.padding()
                }else{
                    VStack{
                        Image(AIModel == "智普AI GLM 4.5 Flash" ? "AI_icon" : "CatAI_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(.infinity)
                            .shadow(color: colorScheme == .light ? Color(.systemGray) : .clear, radius: colorScheme == .light ? 6 : 0)
                            .padding()
                        
                        Text("您好!")
                            .font(.title.bold())
                        Text("我是 \(AIModel)")
                            .font(.title.bold())
                    }
                    .frame(minHeight: Proxy.size.height)
                    .frame(maxWidth: .infinity)
                }
            }.animation(.easeInOut, value: ChatContent)
        }
        
        Spacer()
        
        VStack {
            TextField("你想問什麼？",text: $question)
                .disabled(ChatContent.last == "<aiIdentifierForAPP?>思考中...")
                .padding(.horizontal)
                .submitLabel(.send)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.infinity)
                .onSubmit {
                    print(question)
                    
                    ChatContent.append("<userIdentifierForAPP?>\(removeIdentifier(str: question))")
                    
                    print("loading")
                    
                    ChatContent.append("<aiIdentifierForAPP?>思考中...")
                    
                    callAIModel(role:AIModel,oldPrompt:String(describing: ChatContent),prompt: question) { result in
                        switch result {
                        case .success(let response):
                            print("AI响应: \(response)")
                            ChatContent[ChatContent.count - 1] = "<aiIdentifierForAPP?>\(response)"
                        case .failure(let error):
                            print("发生错误: \(error.localizedDescription)")
                            ChatContent[ChatContent.count - 1] = "<aiIdentifierForAPP?>\(error.localizedDescription)"
                        }
                    }
                    
                    question = ""

                }
        }
        .padding(.horizontal)
        .onChange(of: AIModel) {
            ChatContent = []
        }
    }
    
    
    private func removeIdentifier(str:String) -> String{
        return str.replacingOccurrences(of: "<aiIdentifierForAPP?>", with: "").replacingOccurrences(of: "<userIdentifierForAPP?>", with: "")
    }
}

#Preview {
    ContentView()
}
