//
//  ProviderType.swift
//  GPTalks
//
//  Created by Zabir Raihan on 08/07/2024.
//

import Foundation
import OpenAI

enum ProviderType: String, Codable, CaseIterable, Identifiable {
    case openai
    case anthropic
    case google
    case local
    
    var id: ProviderType { self }
    
    var scheme: String {
        switch self {
        case .openai, .anthropic, .google: "https"
        case .local: "http"
        }
    }
    
    var name: String {
        switch self {
        case .openai: "OpenAI"
        case .anthropic: "Anthropic"
        case .google: "Google"
        case .local: "Local AI"
        }
    }
    
    var imageName: String {
        switch self {
        case .openai: "openai"
        case .anthropic: "anthropic"
        case .google: "google"
        case .local: "ollama"
        }
    }
    
    var imageOffset: CGFloat {
        switch self {
        case .openai, .local: 4
        case .anthropic: 6
        case .google: 12
        }
    }
    
    var defaultHost: String {
        switch self {
        case .openai: "api.openai.com"
        case .anthropic: "api.anthropic.com"
        case .google: "generativelanguage.googleapis.com"
        case .local: "localhost:11434"
        }
    }
    
    var defaultColor: String {
        switch self {
        case .openai: "#00947A"
        case .anthropic: "#E6784B"
        case .google: "#E64335"
        case .local: "#EFEFEF"
        }
    }
    
    func getDefaultModels() -> [AIModel] {
        switch self {
        case .openai: return AIModel.getOpenaiModels()
        case .anthropic: return AIModel.getAnthropicModels()
        case .google: return AIModel.getGoogleModels()
        case .local: return AIModel.getLocalModels()
        }
    }
    
    // TODO: Separate class
    func refreshModels(provider: Provider) async -> [AIModel] {
        switch self {
        case .openai, .local:
            let config: OpenAI.Configuration = .init(
                token: provider.apiKey,
                host: provider.host
            )
            
            let service = OpenAI(configuration: config)
            
            let models = try? await service.models()

            return models?.data.map {
                AIModel(code: $0.id, name: $0.name)
            } ?? []
            
        case .anthropic, .google:
            return self.getDefaultModels()
        }
    }
}
