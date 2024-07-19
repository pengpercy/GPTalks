//
//  ChatInspector.swift
//  GPTalks
//
//  Created by Zabir Raihan on 19/07/2024.
//

import SwiftUI
import SwiftData

struct ChatInspector: View {
    @Bindable var session: Session
    @Query var providers: [Provider]
    
    var body: some View {
        Form {
            Section("Title") {
                HStack(spacing: 0) {
                    title
                    Spacer()
                    generateTitle
                }

            }
            
            Section("Models") {
                ProviderPicker(
                    provider: $session.config.provider,
                    providers: providers.sorted(by: { $0.order < $1.order }),
                    onChange: { newProvider in
                        session.config.model = newProvider.chatModel
                    }
                )
                ModelPicker(model: $session.config.model, models: session.config.provider.chatModels)
            }
            
            Section("Parameters") {
                TemperatureSlider(temperature: $session.config.temperature, shortLabel: true)
                TopPSlider(topP: $session.config.topP)
                FrequencyPenaltySlider(penalty: $session.config.frequencyPenalty, shortLabel: true)
                PresencePenaltySlider(penalty: $session.config.presencePenalty, shortLabel: true)
                MaxTokensPicker(value: $session.config.maxTokens)
            }
            
            Section("System Prompt") {
                sysPrompt
            }
            
            Section("") {
                resetContext
                deleteAllMessages
            }
            .buttonStyle(.plain)
        }
    }
    
    private var title: some View {
        Group {
#if os(macOS)
            TextEditor(text: $session.title)
                .font(.body)
                .textEditorStyle(.plain)
#else
            TextField("Title", text: $session.title)
                .lineLimit(1)
#endif
        }
        .onChange(of: session.title) {
            session.title = String(
                session.title.trimmingCharacters(
                    in: .newlines))
        }
    }
    
    private var sysPrompt: some View {
        #if os(macOS)
        TextEditor(text: $session.config.systemPrompt)
            .font(.body)
            .textEditorStyle(.plain)
            .frame(minHeight: 70, maxHeight: 125)
        #else
        TextField("System Prompt", text: $session.config.systemPrompt, axis: .vertical)
            .lineLimit(5, reservesSpace: true)
        #endif
    }
    
    private var generateTitle: some View {
        Button {
            if session.isStreaming { return }
            Task { await session.generateTitle(forced: true) }
        } label: {
            Image(systemName: "sparkles")
        }
        .buttonStyle(.plain)
    }
    
    private var resetContext: some View {
        Button {
            if session.isStreaming { return }
            if let lastGroup = session.groups.last {
                session.resetContext(at: lastGroup)
            }
        } label: {
            HStack {
                Spacer()
                Text("Reset Context")
                Spacer()
            }
        }
        .foregroundStyle(.orange)
    }
    
    private var deleteAllMessages: some View {
        Button(role: .destructive) {
            if session.isStreaming { return }
            
            session.deleteAllConversations()
        } label: {
            HStack {
                Spacer()
                Text("Delete All Messages")
                Spacer()
            }
        }
        .foregroundStyle(.red)
    }
}

#Preview {
    ChatInspector(session: Session(config: SessionConfig()))
        .modelContainer(for: Provider.self, inMemory: true)
        .formStyle(.grouped)
        .frame(width: 300, height: 700)
}
