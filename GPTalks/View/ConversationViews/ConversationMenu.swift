//
//  ConversationMenu.swift
//  GPTalks
//
//  Created by Zabir Raihan on 04/07/2024.
//

import SwiftUI
import SwiftData

struct ConversationMenu: View {
    @Environment(\.modelContext) var modelContext
    @Environment(SessionVM.self) var sessionVM
    @Environment(\.isQuick) var isQuick
    
    var group: ConversationGroup
    var providers: [Provider]
    
    @Binding var isExpanded: Bool
    var toggleTextSelection: (() -> Void)? = nil
    
    @State var isCopied = false

    var body: some View {
        #if os(macOS)
            HStack {
                buttons
                    .labelStyle(.iconOnly)
            }
        #else
            buttons
        #endif
    }

    @ViewBuilder
    var buttons: some View {
        expandHeight
        
        Section {
            editGroup
            
            regenGroup
        }
    
        Section {
            copyText
            #if !os(macOS)
            selectText
            #endif
        }

        Section {
            resetContext
            
            forkSession
        }
        
        Section {
            deleteGroup
        }
        
        navigate
    }
    
    @ViewBuilder
    var editGroup: some View {
        if !isQuick && group.role == .user {
            HoverScaleButton(icon: "pencil", label: "Edit") {
                group.setupEditing()
            }
            .help("Edit")
        }
    }
    
    @ViewBuilder
    var expandHeight: some View {
        if group.role == .user {
            HoverScaleButton(icon: isExpanded ? "arrow.up.right.and.arrow.down.left" : "arrow.down.left.and.arrow.up.right", label: isExpanded ? "Collapse" : "Expand") {
                withAnimation {
                    isExpanded.toggle()
                    group.session?.proxy?.scrollTo(group, anchor: .top)
                }
            }
            .contentTransition(.symbolEffect(.replace))
            .help("Expand")
        }
    }

    var resetContext: some View {
        HoverScaleButton(icon: "rectangle.compress.vertical", label: "Reset Context") {
            group.resetContext()
        }
    }

    var forkSession: some View {
        HoverScaleButton(icon: "arrow.branch", label: "Fork Session") {
            if let newSession = group.session?.copy(from: group, purpose: .chat) {
                sessionVM.fork(session: newSession, modelContext: modelContext)
            }
        }
    }

    var copyText: some View {
        HoverScaleButton(icon: isCopied ? "checkmark" : "square.on.square", label: "Copy Text") {
            group.activeConversation.content.copyToPasteboard()
            
            isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isCopied = false
            }
        }
        .contentTransition(.symbolEffect(.replace))
    }
    
    var selectText: some View {
        Button {
            toggleTextSelection?()
        } label: {
            Label("Select Text", systemImage: "text.cursor")
                .help("Select Text")
        }
    }

    var deleteGroup: some View {
        HoverScaleButton(icon: "trash", label: "Delete") {
            group.deleteSelf()
        }
    }

    var regenGroup: some View {
        #if os(macOS)
        Menu {
            ForEach(providers) { provider in
                Menu {
                    ForEach(provider.chatModels.filter { $0.isEnabled }.sorted(by: { $0.order < $1.order })) { model in
                        Button {
                            group.session?.config.provider = provider
                            group.session?.config.model = model
                            if group.role == .assistant {
                                Task { 
                                    await group.session?.regenerate(group: group)
                                }
                            } else if group.role == .user {
                                group.setupEditing()
                                Task { 
                                    await group.session?.sendInput()
                                }
                            }
                        } label: {
                            Text(model.name)
                        }
                    }
                } label: {
                    Text(provider.name)
                }
            }
        } label: {
            Label("Regenerate", systemImage: "arrow.2.circlepath")
        } primaryAction: {
            performPrimaryAction()
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        #else
        Button(action: performPrimaryAction) {
            Label("Regenerate", systemImage: "arrow.2.circlepath")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .fixedSize()
        #endif
    }

    private func performPrimaryAction() {
        if group.role == .assistant {
            Task { 
                await group.session?.regenerate(group: group)
            }
        } else if group.role == .user {
            group.setupEditing()
            Task { 
                await group.session?.sendInput()
            }
        }
    }


    var navigate: some View {
        var canNavigateLeft: Bool {
            guard let session = group.session else { return false }
            let groups = session.groups
            if let indexOfCurrentGroup = groups.firstIndex(where: { $0.id == group.id }) {
                if groups.count >= 2 && indexOfCurrentGroup >= groups.count - 2 {
                    return group.conversations.count > 1 && group.canGoLeft
                }
            }
            return false
        }
        
        var canNavigateRight: Bool {
            guard let session = group.session else { return false }
            let groups = session.groups
            if let indexOfCurrentGroup = groups.firstIndex(where: { $0.id == group.id }) {
                if groups.count >= 2 && indexOfCurrentGroup >= groups.count - 2 {
                    return group.conversations.count > 1 && group.canGoRight
                }
            }
            return false
        }
        
        var shouldShowButtons: Bool {
            guard let session = group.session else { return false }
            let groups = session.groups
            if let indexOfCurrentGroup = groups.firstIndex(where: { $0.id == group.id }) {
                return groups.count >= 2 && indexOfCurrentGroup >= groups.count - 2
            }
            return false
        }
        
        return Group {
            #if os(macOS)
            if group.conversations.count > 1 && group.role == .assistant {
                HoverScaleButton(icon: "chevron.left", label: "Previous") {
                    group.setActiveToLeft()
                }
                .disabled(!shouldShowButtons || !canNavigateLeft)
                .help("Previous")
                
//                Text(
//                    "\(group.activeConversationIndex + 1)/\(group.conversations.count)"
//                )
//                .foregroundStyle(.secondary)
//                .frame(width: 30)
                
                HoverScaleButton(icon: "chevron.right", label: "Next") {
                    group.setActiveToRight()
                }
                .disabled(!shouldShowButtons || !canNavigateRight)
                .help("Next")
            }
            #else
            if group.conversations.count > 1 && group.role == .assistant {
                Section("Iterations: \(group.activeConversationIndex + 1)/\(group.conversations.count)") {
                    HoverScaleButton(icon: "chevron.left", label: "Previous") {
                        group.setActiveToLeft()
                    }
                    .disabled(!shouldShowButtons || !canNavigateLeft)
                    
                    HoverScaleButton(icon: "chevron.right", label: "Next") {
                        group.setActiveToRight()
                    }
                    .disabled(!shouldShowButtons || !canNavigateRight)
                }
            }
            #endif
        }
    }
}

#Preview {
    let config = SessionConfig()
    let session = Session(config: config)

    let userConversation = Conversation(role: .user, content: "Hello, World!")
    let assistantConversation = Conversation(
        role: .assistant, content: "Hello, World!")

    let group = ConversationGroup(
        conversation: userConversation, session: session)
    group.addConversation(
        Conversation(role: .user, content: "This is second."))
    group.addConversation(
        Conversation(role: .user, content: "This is third message."))
    let group2 = ConversationGroup(
        conversation: assistantConversation, session: session)

    let providers: [Provider] = []
    
    return VStack {
        ConversationGroupView(group: group, providers: providers)
        ConversationGroupView(group: group2, providers: providers)
    }
    .environment(SessionVM())
    .frame(width: 500)
    .padding()
}
