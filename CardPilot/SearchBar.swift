//
//  SearchBar.swift
//  CardPilot
//
//  Created by Lei Yang on 9/8/2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search sessions...", text: $text)
                    .onTapGesture {
                        withAnimation {
                            isEditing = true
                        }
                    }
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            
            if isEditing {
                Button("Cancel") {
                    withAnimation {
                        isEditing = false
                        text = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
            }
        }
    }
}

#Preview {
    SearchBar(text: .constant(""))
        .padding()
}
