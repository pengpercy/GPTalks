//
//  ChatModelList.swift
//  GPTalks
//
//  Created by Zabir Raihan on 23/07/2024.
//

import SwiftUI

struct ChatModelList: View {
    @Environment(\.modelContext) var modelContext
    #if !os(macOS)
    @Environment(\.editMode) var editMode
    #endif
    @Bindable var provider: Provider

    @State var showAdder = false
    @State var selections: Set<ChatModel> = []
    @State var searchText = ""
    @State var isRefreshing = false
    
    var body: some View {
        Group {
            #if os(macOS)
            macOSContent
            #else
            iOSContent
            #endif
        }
        .sheet(isPresented: $showAdder) {
            ChatModelAdder(provider: provider)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addButton
            }
        }
        .searchable(text: $searchText, placement: searchPlacement)
    }
    
    var searchPlacement: SearchFieldPlacement {
        #if os(macOS)
        return .toolbar
        #else
        return .navigationBarDrawer(displayMode: .always)
        #endif
    }
    
    var filteredModels: [ChatModel] {
        let filtered = searchText.isEmpty ? provider.chatModels : provider.chatModels.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.code.localizedCaseInsensitiveContains(searchText) }
        return filtered
    }
}

// MARK: - common foreach
extension ChatModelList {
    var collectiom: some View {
        ForEach(filteredModels) { model in
            ChatModelRow(model: model, provider: provider) 
            .tag(model)
        }
        .onDelete(perform: deleteItems)
    }
    
    private func deleteItems(offsets: IndexSet) {
        provider.chatModels.remove(atOffsets: offsets)
    }
    
}

// MARK: - macOS Specific Views
#if os(macOS)
extension ChatModelList {
    var macOSContent: some View {
        Form {
            List(selection: $selections) {
                Section(header: sectionHeader) {
                    collectiom
                }
            }
            .labelsHidden()
            .alternatingRowBackgrounds()
        }
        .formStyle(.grouped)
    }
    
    var sectionHeader: some View {
        HStack(spacing: 0) {
            Text("Code")
                .frame(maxWidth: 300, alignment: .leading)
            Text("Name")
                .frame(maxWidth: 205, alignment: .leading)
            Text("Test")
                .frame(maxWidth: 35, alignment: .center)
        }
    }
}
#endif

// MARK: - iOS Specific Views
#if !os(macOS)
extension ModelListView {
    var iOSContent: some View {
        List(selection: $selections) {
            collectiom
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                HStack {
                    EditButton()
                    Spacer()
                    if editMode?.wrappedValue == .active {
                        editMenu
                    }
                }
            }
        }
    }
}
#endif

// MARK: - Shared Components
extension ChatModelList {
    @ViewBuilder
    var addButton: some View {
        if isRefreshing {
            Button(action: {}) {
                Label("Refreshing", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
            }
            .symbolEffect(.rotate, isActive: isRefreshing)
            .disabled(true)
        } else {
            Menu {
                Button {
                    Task {
                        await refreshModels()
                    }
                } label: {
                    Label("Refresh Models", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                }
                
                Section {
                    Button(action: { showAdder = true }) {
                        Label("Add Custom Model", systemImage: "plus")
                    }
                }
            } label: {
                Label("Add", systemImage: "plus")
            }
        }
    }
    
    var editMenu: some View {
        Menu {
            Section {
                Button(action: { selections = Set(filteredModels) }) {
                    Label("Select All", systemImage: "checkmark.circle.fill")
                }
                
                Button(action: { selections.removeAll() }) {
                    Label("Deselect All", systemImage: "xmark.circle")
                }
            }
        } label: {
            Label("Actions", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }
    
    func refreshModels() async {
        isRefreshing = true
        await provider.refreshModels()
        isRefreshing = false
    }
}


#Preview {
    ChatModelList(provider: .openAIProvider)
}
