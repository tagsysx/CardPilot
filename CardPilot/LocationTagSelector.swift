//
//  LocationTagSelector.swift
//  CardPilot
//
//  Created by Lei Yang on 12/19/2024.
//

import SwiftUI

struct LocationTagSelector: View {
    @Binding var selectedTag: String?
    @StateObject private var tagManager = LocationTagManager()
    @State private var showingAddTagSheet = false
    @State private var newTagName = ""
    @State private var newTagColor = "blue"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.blue)
                Text("Location Tag")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingAddTagSheet = true }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
            
            // 当前选中的标签
            if let selectedTag = selectedTag {
                HStack {
                    Text(selectedTag)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Button("Change") {
                        self.selectedTag = nil
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            } else {
                Text("No tag selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // 常用标签选择
            if !tagManager.availableTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Select")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(tagManager.getMostUsedTags(limit: 6)) { tag in
                            Button(action: {
                                selectedTag = tag.name
                                tag.incrementUsage()
                            }) {
                                Text(tag.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .frame(maxWidth: .infinity)
                                    .background(tagColor(for: tag.color).opacity(0.2))
                                    .foregroundColor(tagColor(for: tag.color))
                                    .cornerRadius(6)
                            }
                            .disabled(selectedTag == tag.name)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddTagSheet) {
            AddTagSheet(
                tagName: $newTagName,
                tagColor: $newTagColor,
                onSave: addNewTag
            )
        }
    }
    
    // 添加新标签
    private func addNewTag() {
        guard !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newTag = tagManager.addTag(name: newTagName.trimmingCharacters(in: .whitespacesAndNewlines), color: newTagColor)
        selectedTag = newTag.name
        newTagName = ""
        newTagColor = "blue"
    }
    
    // 根据颜色名称获取对应的Color
    private func tagColor(for colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

// 添加标签的Sheet视图
struct AddTagSheet: View {
    @Binding var tagName: String
    @Binding var tagColor: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tag Name")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    TextField("Enter tag name", text: $tagName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tag Color")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(LocationTag.availableColors, id: \.self) { color in
                            Button(action: { tagColor = color }) {
                                Circle()
                                    .fill(tagColor(for: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(tagColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // 根据颜色名称获取对应的Color
    private func tagColor(for colorName: String) -> Color {
        switch colorName {
        case "red": return .red
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray": return .gray
        default: return .blue
        }
    }
}

#Preview {
    LocationTagSelector(selectedTag: .constant(nil))
        .padding()
}
