//
//  TransactionInputView.swift
//  CardPilot
//
//  Manual transaction input for Apple Pay data
//

import SwiftUI
import SwiftData

struct TransactionInputView: View {
    @State private var amount: String = ""
    @State private var merchantName: String = ""
    @State private var category: TransactionCategory = .other
    @State private var paymentMethod: PaymentMethod = .creditCard
    @State private var notes: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transaction Information") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                        Text("USD")
                    }
                    
                    TextField("Merchant Name", text: $merchantName)
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(TransactionCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
                
                Section("Notes") {
                    TextField("Transaction notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Note") {
                    Text("Due to iOS security restrictions, Apple Pay transaction data cannot be automatically retrieved. Please manually enter transaction information to complete the data record.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Transaction Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(amount.isEmpty || merchantName.isEmpty)
                }
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Decimal(string: amount) else { return }
        
        let transaction = ManualTransaction(
            amount: amountValue,
            merchantName: merchantName,
            category: category,
            paymentMethod: paymentMethod,
            notes: notes.isEmpty ? nil : notes,
            timestamp: Date()
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save transaction record: \(error)")
        }
    }
}

// MARK: - Data Models

@Model
final class ManualTransaction {
    var amount: Decimal
    var merchantName: String
    var categoryRawValue: String
    var paymentMethodRawValue: String
    var notes: String?
    var timestamp: Date
    
    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }
    
    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRawValue) ?? .other }
        set { paymentMethodRawValue = newValue.rawValue }
    }
    
    init(amount: Decimal, merchantName: String, category: TransactionCategory, 
         paymentMethod: PaymentMethod, notes: String? = nil, timestamp: Date = Date()) {
        self.amount = amount
        self.merchantName = merchantName
        self.categoryRawValue = category.rawValue
        self.paymentMethodRawValue = paymentMethod.rawValue
        self.notes = notes
        self.timestamp = timestamp
    }
}

enum PaymentMethod: String, CaseIterable {
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case cash = "Cash"
    case alipay = "Alipay"
    case wechatPay = "WeChat Pay"
    case other = "Other"
}

enum TransactionCategory: String, CaseIterable {
    case food = "Food & Dining"
    case transport = "Transportation"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case healthcare = "Healthcare"
    case education = "Education"
    case utilities = "Utilities"
    case travel = "Travel"
    case other = "Other"
}

#Preview {
    TransactionInputView()
}
