//
//  ConversationGroupView.swift
//  GPTalks
//
//  Created by Zabir Raihan on 06/07/2024.
//

import SwiftUI

struct ConversationGroupView: View {
    var group: ConversationGroup
    
    @State var isHovered: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Group {
                switch group.role {
                case .user:
                    UserMessage(conversation: group.activeConversation)
                        .padding(.top, 5)
                case .assistant:
                    AssistantMessage(conversation: group.activeConversation)
                        .padding(.top, 5)
                default:
                    Text("Unknown role")
                }
            }
            #if os(iOS)
            .opacity(0.9)
            #endif
            
            if group.session?.groups.firstIndex(where: { $0 == group }) == group.session?.resetMarker {
                ContextResetDivider() {
                    group.session?.resetMarker = nil
                }
                .padding(.vertical)
            }
        }
    }
}


#Preview {
    let config = SessionConfig()
    let session = Session(config: config)

    let userConversation = Conversation(role: .user, content: "Hello, World!")
    let assistantConversation = Conversation(
        role: .assistant, content: """
        Hello, World! \n
        Hi boss
        """)

    let group = ConversationGroup(
        conversation: userConversation, session: session)
    let group2 = ConversationGroup(
        conversation: assistantConversation, session: session)

    VStack {
        ConversationGroupView(group: group)
        ConversationGroupView(group: group2)
    }
    .frame(width: 400)
    .padding()
}
