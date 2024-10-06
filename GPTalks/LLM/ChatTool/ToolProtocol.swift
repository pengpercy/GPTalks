//
//  ToolProtocol.swift
//  GPTalks
//
//  Created by Zabir Raihan on 07/10/2024.
//

import Foundation
import SwiftOpenAI
import GoogleGenerativeAI

protocol ToolProtocol {
    static var openai: ChatCompletionParameters.Tool { get }
    static var google: Tool { get }
    static var vertex: [String: Any] { get }
    static var tokenCount: Int { get }
    static var displayName: String { get }
    static var icon: String { get }
    static func process(arguments: String) async throws -> ToolData
}
