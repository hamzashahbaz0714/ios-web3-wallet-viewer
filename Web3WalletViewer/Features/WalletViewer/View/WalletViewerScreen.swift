//
//  WalletViewerScreen.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import SwiftUI

struct WalletViewerScreen: View {
    @StateObject private var vm = WalletViewerViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Wallet Input")) {
                    TextField("0x...", text: $vm.address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(.body, design: .monospaced))
                    
                    Picker("Chain", selection: $vm.selectedChain) {
                        ForEach(Chain.allCases) { chain in
                            Text(chain.rawValue).tag(chain)
                        }
                    }
                    
                    Button {
                        Task { await vm.loadWallet() }
                    } label: {
                        if vm.isLoading {
                            HStack {
                                ProgressView()
                                Text("Loading...")
                            }
                        } else {
                            Text("Load Wallet")
                        }
                    }
                    .disabled(vm.isLoading)
                }
                
                if let error = vm.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                if let summary = vm.summary {
                    Section(header: Text("Summary")) {
                        LabeledContent("Address", value: summary.address)
                        LabeledContent("Chain", value: summary.chain.rawValue)
                        LabeledContent("Balance", value: summary.nativeBalance)
                    }
                    
                    Section(header: Text("Tokens")) {
                        ForEach(summary.tokens) { token in
                            HStack {
                                Text(token.symbol)
                                Spacer()
                                Text(token.amount)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wallet Viewer")
        }
    }
}
struct WalletViewerScreen_Previews: PreviewProvider {
    static var previews: some View {
        WalletViewerScreen()
    }
}


