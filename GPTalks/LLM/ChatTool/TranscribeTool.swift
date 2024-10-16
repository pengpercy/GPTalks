//
//  TranscribeTool.swift
//  GPTalks
//
//  Created by Zabir Raihan on 07/10/2024.
//

import Foundation
import OpenAI
import GoogleGenerativeAI
import SwiftData

struct TranscribeTool: ToolProtocol {
    static let toolName: String = "transcribe"
    static let displayName: String = "Transcribe"
    static let icon: String = "waveform"
    
    struct TranscribeArgs: Codable {
        let conversationID: String
        let fileNames: [String]
    }
    
    static func process(arguments: String) async throws -> ToolData {
        var totalContent: String = ""
        let args = try TranscribeTool.getFileIds(from: arguments)
        
        let modelContext = DatabaseService.shared.modelContext
        let uuid = UUID(uuidString: args.conversationID)!
        
        let fetchDescriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { conversation in
                conversation.id == uuid
            }
        )
        let conversations = try modelContext.fetch(fetchDescriptor)
        
        var fetchDefaults = FetchDescriptor<ProviderDefaults>()
        fetchDefaults.fetchLimit = 1
        let fetchedProviders = try modelContext.fetch(fetchDefaults)
        guard let provider = fetchedProviders.first?.toolSTTProvider else {
            throw RuntimeError("No STT provider found")
        }
        
        if let conversation = conversations.first {
            for name in args.fileNames {
                if let typedData = conversation.dataFiles.first(where: { $0.fileName == name }) {
                    totalContent += try await transcribeText(provider: provider, model: provider.sttModel, typedData: typedData)
                }
            }
            
            return .init(string: totalContent)
        } else {
            throw RuntimeError("No conversation found with the given ID")
        }
    }

    private static func getFileIds(from jsonString: String) throws -> TranscribeArgs {
        let jsonData = jsonString.data(using: .utf8)!
        let audioArgs = try JSONDecoder().decode(TranscribeArgs.self, from: jsonData)
        return audioArgs
    }
    
    private static func transcribeText(provider: Provider, model: STTModel, typedData: TypedData) async throws -> String {
        let service = OpenAIService.getService(provider: provider)

        
        if let fileType = typedData.derivedFileType {
            let query = AudioTranscriptionQuery(file: typedData.data, fileType: fileType, model: model.code)
            let result = try await service.audioTranscriptions(query: query)
            return result.text
        } else {
            throw RuntimeError("Invalid audio/video file type")
        }
        
    }
    
    static let tokenCount = countTokensFromText(description)
    
    static let description: String = """
        You can open and access contents of audio files. Just respond with a list of file names without file extensions
        """
    
    static var openai: ChatQuery.ChatCompletionToolParam {
        .init(function:
                .init(
                    name: toolName,
                    description: description,
                    parameters:
                        .init(
                            type: .object,
                            properties: [
                                "conversationID":
                                        .init(
                                            type: .string,
                                            description: "The conversation ID"
                                        ),
                                "fileNames":
                                    .init(
                                        type: .array,
                                        description: "The array of audio file ids to access",
                                        items: .init(type: .string)
                                    )
                            ]
                        )
                )
        )
    }
    
    static var google: Tool {
        Tool(functionDeclarations: [
            FunctionDeclaration(
                name: toolName,
                description: description,
                parameters: [
                    "conversationID": Schema(
                        type: .string,
                        description: "The conversation ID"
                    ),
                    "fileNames": Schema(
                        type: .array,
                        description: "The array of audio file ids to access",
                        items: Schema(type: .string)
                    )
                ],
                requiredParameters: ["conversationID", "fileNames"]
            )
        ])
    }
    
    static var vertex: [String: Any] {
         [
            "name": toolName,
            "description": description,
            "input_schema": [
                "type": "object",
                "properties": [
                    "conversationID": [
                        "type": "string",
                        "description": "The conversation ID"
                    ],
                    "fileNames": [
                        "type": "array",
                        "description": "The array of audio file ids to access",
                        "items": [
                            "type": "string"
                        ],
                        "maxItems": 5
                    ]
                ],
                "required": ["url_list"]
            ]
        ]
    }
}
