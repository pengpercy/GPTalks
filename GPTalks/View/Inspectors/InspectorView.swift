//
//  InspectorView.swift
//  GPTalks
//
//  Created by Zabir Raihan on 19/07/2024.
//

import SwiftUI

struct InspectorView: View {
    @Environment(SessionVM.self) private var sessionVM
    @Binding var showingInspector: Bool
    
    var body: some View {
        Group {
            switch sessionVM.state {
            case .chats:
                if sessionVM.selections.count == 1, let first = sessionVM.selections.first {
                    ChatInspector(session: first)
                }
            case .images:
                if sessionVM.imageSelections.count == 1, let first = sessionVM.imageSelections.first {
                    ImageInspector(session: first)
                }
            }
        }
        .navigationTitle("Config")
        .inspectorColumnWidth(min: 275, ideal: 300, max: 350)
        .toolbar {
            if showingInspector, sessionVM.selections.count == 1, let first = sessionVM.selections.first {
                Text("Tokens: " + first.tokenCounter.formatToK()).foregroundStyle(.secondary)
                
                Spacer()
            }
                
            Button {
                showingInspector.toggle()
            } label: {
                Label("Inspector", systemImage: "info.circle")
            }
        }
    }
}

//#Preview {
//    InspectorView()
//}
