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
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        headerCard
                        inputCard
                        if let error = vm.errorMessage {
                            errorCard(error)
                        }
                        if let summary = vm.summary {
                            summaryCard(summary)
                            tokensCard(summary.tokens)
                        } else if !vm.isLoading {
                            emptyStateCard
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Wallet Viewer")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Sections

    private var headerCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Read-only Wallet Dashboard")
                    .font(.headline)
                Text("Track balances safely without importing private keys.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Wallet Input")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Wallet Address")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                TextField("0x...", text: $vm.address)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(.separator).opacity(0.35), lineWidth: 1)
                    )

                Text("Tip: EVM addresses are 42 chars and start with 0x.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Network")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Picker("Chain", selection: $vm.selectedChain) {
                    ForEach(Chain.allCases) { chain in
                        Text(chain.rawValue).tag(chain)
                    }
                }
                .pickerStyle(.segmented)
            }

            Button {
                Task { await vm.loadWallet() }
            } label: {
                HStack(spacing: 8) {
                    if vm.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }

                    Text(vm.isLoading ? "Loading..." : "Load Wallet")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(vm.isLoading || vm.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//            Text("Live native balance from JSON-RPC")
//                .font(.footnote)
//                .foregroundStyle(.secondary)

        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("Something went wrong")
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    private func summaryCard(_ summary: WalletSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.headline)
                Spacer()
                Text(summary.chain.symbol)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)
            }

            infoRow("Address", summary.address, monospaced: true)
            Divider().opacity(0.35)
            infoRow("Chain", summary.chain.rawValue)
            Divider().opacity(0.35)
            infoRow("Balance", summary.nativeBalance, emphasize: true)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }

    private func tokensCard(_ tokens: [TokenBalance]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tokens")
                    .font(.headline)
                Spacer()
                Text("\(tokens.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.15), in: Capsule())
            }

            if tokens.isEmpty {
                Text("No tokens found for this wallet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                VStack(spacing: 10) {
                    ForEach(tokens) { token in
                        HStack {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(.blue.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text(String(token.symbol.prefix(1)))
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.blue)
                                    )
                                Text(token.symbol)
                                    .fontWeight(.semibold)
                            }

                            Spacer()
                            Text(token.amount)
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        )
    }

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "wallet.pass")
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text("No wallet loaded yet")
                .font(.headline)
            Text("Enter an address, pick a network, and tap “Load Wallet”.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func infoRow(_ title: String, _ value: String, monospaced: Bool = false, emphasize: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .system(.subheadline, design: .monospaced) : .subheadline)
                .fontWeight(emphasize ? .semibold : .regular)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    WalletViewerScreen()
}
