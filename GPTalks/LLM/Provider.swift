//
//  Provider.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import Foundation
import SwiftData
import OpenAI
import GoogleGenerativeAI

@Model
class Provider {
    var id: UUID = UUID()
    var date: Date = Date()
    var order: Int = 0
    
    var name: String = ""
    var host: String = ""
    @Attribute(.allowsCloudEncryption)
    var apiKey: String = ""
    
    var type: ProviderType
    var isPersistent: Bool = false  // added by the app by default and are not deletable
    var extraInfo: String = ""
    
    var color: String = "#00947A"
    var isEnabled: Bool = true
    var supportsImage: Bool = false
    
    @Relationship(deleteRule: .cascade)
    var chatModel: AIModel
    @Relationship(deleteRule: .cascade)
    var quickChatModel: AIModel
    @Relationship(deleteRule: .cascade)
    var titleModel: AIModel
    @Relationship(deleteRule: .cascade)
    var imageModel: AIModel
    @Relationship(deleteRule: .cascade)
    var toolImageModel: AIModel
    
    @Relationship(deleteRule: .cascade)
    var chatModels: [AIModel] = []
    
    @Relationship(deleteRule: .cascade)
    var imageModels: [AIModel] = []

    public init(id: UUID = UUID(),
                date: Date = Date(),
                order: Int = 0,
                name: String,
                host: String,
                apiKey: String,
                type: ProviderType,
                color: String,
                isEnabled: Bool,
                supportsImage: Bool,
                chatModel: AIModel,
                quickChatModel: AIModel,
                titleModel: AIModel,
                imageModel: AIModel,
                toolImageModel: AIModel,
                chatModels: [AIModel] = [],
                imageModels: [AIModel] = []) {
        self.id = id
        self.date = date
        self.order = order
        self.name = name
        self.host = host
        self.apiKey = apiKey
        self.type = type
        self.color = color
        self.isEnabled = isEnabled
        self.supportsImage = supportsImage
        self.chatModel = chatModel
        self.quickChatModel = quickChatModel
        self.titleModel = titleModel
        self.imageModel = imageModel
        self.toolImageModel = toolImageModel
        self.chatModels = chatModels
        self.imageModels = imageModels
    }
    
    
    static func factory(type: ProviderType, isDummy: Bool = false) -> Provider {
        let demoModel = AIModel.gpt4
        let chatModels = type.getDefaultModels()
        let imageModels = type == .openai ? AIModel.getOpenImageModels() : []
        
        let provider = Provider(
            name: type.name,
            host: type.defaultHost,
            apiKey: "",
            type: type,
            color: type.defaultColor,
            isEnabled: !isDummy,
            supportsImage: type == .openai,
            chatModel: chatModels.first ?? demoModel,
            quickChatModel: chatModels.first ?? demoModel,
            titleModel: chatModels.first ?? demoModel,
            imageModel: imageModels.first ?? demoModel,
            toolImageModel: imageModels.first ?? demoModel,
            chatModels: chatModels,
            imageModels: imageModels
        )
        
        return provider
    }
}

extension Provider {
    func refreshModels() async {
        let refreshedModels: [AIModel] = await type.getService().refreshModels(provider: self)
        
        for model in refreshedModels {
            if !chatModels.contains(where: { $0.code == model.code }) {
                chatModels.append(model)
            }
        }
    }
    
    func testModel(model: AIModel) async -> Bool {
        let service = type.getService()
        let result = await service.testModel(provider: self, model: model)
        model.lastTestResult = result
        return result
    }
}

extension Provider {
    func models(for type: ModelType) -> [AIModel] {
        switch type {
        case .chat:
            return chatModels
        case .image:
            return imageModels
        // Add more cases here as you add more model types
        }
    }

    func setModels(_ models: [AIModel], for type: ModelType) {
        switch type {
        case .chat:
            chatModels = models
        case .image:
            imageModels = models
        // Add more cases here as you add more model types
        }
    }

    func addModel(_ model: AIModel, for type: ModelType) {
        switch type {
        case .chat:
            chatModels.append(model)
        case .image:
            imageModels.append(model)
        // Add more cases here as you add more model types
        }
    }

    func removeModel(_ model: AIModel, for type: ModelType, permanently: Bool = true) {
        switch type {
        case .chat:
            chatModels.removeAll { $0.id == model.id }
        case .image:
            imageModels.removeAll { $0.id == model.id }
        // Add more cases here as you add more model types
        }
        if permanently {
            model.modelContext?.delete(model)
        }
    }
}
