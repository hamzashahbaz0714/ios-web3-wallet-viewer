//
//  WalletViewerScreen.swift
//  Web3WalletViewer
//
//  Created by Hamza Shahbaz on 13/02/2026.
//

import SwiftUI

// MARK: - Theme

private enum WalletTheme {
    // Colors
    static let accentPrimary = Color(red: 0.29, green: 0.45, blue: 1.0)
    static let accentSecondary = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let accentTertiary = Color(red: 0.18, green: 0.82, blue: 0.72)
    static let destructive = Color(red: 0.96, green: 0.55, blue: 0.22)
    static let surfaceTint = Color(red: 0.29, green: 0.45, blue: 1.0).opacity(0.06)
    static let borderLight = Color.white.opacity(0.18)
    static let borderSubtle = Color(.separator).opacity(0.25)
    static let validGreen = Color(red: 0.20, green: 0.78, blue: 0.45)
    static let invalidRed = Color(red: 0.94, green: 0.33, blue: 0.31)

    // Radii
    static let cardRadius: CGFloat = 20
    static let innerRadius: CGFloat = 14
    static let chipRadius: CGFloat = 10

    // Spacing
    static let cardPadding: CGFloat = 18
    static let sectionSpacing: CGFloat = 18
}

// MARK: - Address Validation

private enum AddressValidation {
    case empty
    case valid
    case invalid(String)

    static func validate(_ address: String) -> AddressValidation {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if !trimmed.hasPrefix("0x") {
            return .invalid("Address must start with 0x")
        }
        if trimmed.count != 42 {
            return .invalid("Address must be 42 characters (\(trimmed.count)/42)")
        }
        let hexPart = String(trimmed.dropFirst(2))
        let isHex = hexPart.allSatisfy { $0.isHexDigit }
        if !isHex {
            return .invalid("Address contains invalid characters")
        }
        return .valid
    }

    var borderColor: Color {
        switch self {
        case .empty: return WalletTheme.borderSubtle
        case .valid: return WalletTheme.validGreen.opacity(0.5)
        case .invalid: return WalletTheme.invalidRed.opacity(0.5)
        }
    }

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

// MARK: - Haptics

private enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct WalletViewerScreen: View {
    @StateObject private var vm = WalletViewerViewModel()
    @State private var appeared = false
    @State private var copiedToast = false
    @State private var loadButtonPressed = false
    @FocusState private var addressFieldFocused: Bool

    private var addressValidation: AddressValidation {
        AddressValidation.validate(vm.address)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                scrollContent

                // Copied toast overlay
                if copiedToast {
                    VStack {
                        Spacer()
                        copiedToastView
                            .padding(.bottom, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .navigationTitle("Wallet Viewer")
            .navigationBarTitleDisplayMode(.large)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: copiedToast)
        }
    }

    // MARK: - Copied Toast

    private var copiedToastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WalletTheme.validGreen)
            Text("Address copied")
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
        .overlay(
            Capsule()
                .stroke(WalletTheme.borderLight, lineWidth: 0.5)
        )
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    WalletTheme.accentPrimary.opacity(0.04),
                    WalletTheme.accentSecondary.opacity(0.05),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    WalletTheme.accentPrimary.opacity(0.06),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 400
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: WalletTheme.sectionSpacing) {
                headerCard
                    .cardEntrance(index: 0, appeared: appeared)

                inputCard
                    .cardEntrance(index: 1, appeared: appeared)

                if let error = vm.errorMessage {
                    errorCard(error)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }

                if vm.isLoading {
                    shimmerLoadingCard
                        .transition(.opacity)
                } else if let summary = vm.summary {
                    summaryCard(summary)
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                    tokensCard(summary.tokens)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    emptyStateCard
                        .cardEntrance(index: 2, appeared: appeared)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: vm.summary != nil)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.errorMessage)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: vm.isLoading)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .refreshable {
            guard vm.summary != nil else { return }
            Haptics.impact(.light)
            await vm.loadWallet()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                WalletTheme.accentPrimary.opacity(0.15),
                                WalletTheme.accentSecondary.opacity(0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [WalletTheme.accentPrimary, WalletTheme.accentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Read-only Dashboard")
                    .font(.system(size: 17, weight: .semibold, design: .default))
                Text("Track balances safely — no private keys needed.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(WalletTheme.cardPadding)
        .glassCard()
    }

    // MARK: - Input Card

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Wallet Input", systemImage: "pencil.and.list.clipboard")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)

            // Address field
            VStack(alignment: .leading, spacing: 6) {
                Text("Wallet Address")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                // Text field with paste button
                HStack(spacing: 0) {
                    TextField("0x...", text: $vm.address)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(.body, design: .monospaced))
                        .focused($addressFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            addressFieldFocused = false
                        }
                        .padding(.leading, 14)
                        .padding(.vertical, 13)

                    // Paste from clipboard button
                    Button {
                        if let clipboardString = UIPasteboard.general.string {
                            vm.address = clipboardString
                            Haptics.impact(.light)
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(WalletTheme.accentPrimary.opacity(0.7))
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Paste address from clipboard")
                    .padding(.trailing, 6)
                }
                .background(
                    RoundedRectangle(cornerRadius: WalletTheme.innerRadius, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: WalletTheme.innerRadius, style: .continuous)
                        .stroke(addressValidation.borderColor, lineWidth: 1)
                )
                .animation(.easeInOut(duration: 0.2), value: vm.address)

                // Validation hint or default tip
                addressHintView
            }

            // Recent addresses
            if !vm.recentAddresses.isEmpty {
                recentAddressesSection
            }

            // Network picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Network")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Picker("Chain", selection: $vm.selectedChain) {
                    ForEach(Chain.allCases) { chain in
                        Text(chain.rawValue).tag(chain)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Load button
            loadButton
        }
        .padding(WalletTheme.cardPadding)
        .glassCard()
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    addressFieldFocused = false
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(WalletTheme.accentPrimary)
            }
        }
    }

    @ViewBuilder
    private var addressHintView: some View {
        switch addressValidation {
        case .empty:
            Text("EVM addresses are 42 characters starting with 0x")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.quaternary)
                .padding(.leading, 2)
        case .valid:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(WalletTheme.validGreen)
                Text("Valid address format")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WalletTheme.validGreen)
            }
            .padding(.leading, 2)
            .transition(.opacity)
        case .invalid(let message):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(WalletTheme.invalidRed)
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(WalletTheme.invalidRed)
            }
            .padding(.leading, 2)
            .transition(.opacity)
        }
    }

    private var recentAddressesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Recent")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .kerning(0.5)
                Spacer()
                Button {
                    Haptics.impact(.light)
                    vm.clearRecent()
                } label: {
                    Text("Clear")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(WalletTheme.accentPrimary)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.recentAddresses, id: \.self) { addr in
                        Button {
                            Haptics.selection()
                            vm.selectRecent(addr)
                        } label: {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(WalletTheme.accentPrimary.opacity(0.12))
                                    .frame(width: 6, height: 6)
                                Text(shortAddress(addr))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: WalletTheme.chipRadius, style: .continuous)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: WalletTheme.chipRadius, style: .continuous)
                                    .stroke(WalletTheme.borderSubtle, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Use recent address \(shortAddress(addr))")
                    }
                }
            }
        }
    }

    private var loadButton: some View {
        let isDisabled = vm.isLoading || vm.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return Button {
            Haptics.impact(.medium)
            addressFieldFocused = false
            Task { await vm.loadWallet() }
        } label: {
            HStack(spacing: 8) {
                if vm.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(vm.isLoading ? "Loading..." : "Load Wallet")
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        WalletTheme.accentPrimary,
                        WalletTheme.accentSecondary.opacity(0.85)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: WalletTheme.innerRadius, style: .continuous))
            .shadow(color: WalletTheme.accentPrimary.opacity(isDisabled ? 0 : 0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1.0)
        .scaleEffect(loadButtonPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: loadButtonPressed)
        .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in loadButtonPressed = true }
                .onEnded { _ in loadButtonPressed = false }
        )
        .accessibilityLabel(vm.isLoading ? "Loading wallet" : "Load wallet")
    }

    // MARK: - Shimmer Loading Card

    private var shimmerLoadingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Loading...")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                ShimmerView()
                    .frame(width: 50, height: 24)
                    .clipShape(Capsule())
            }

            ShimmerView()
                .frame(height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.trailing, 40)

            divider

            ShimmerView()
                .frame(height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.trailing, 80)

            divider

            HStack {
                ShimmerView()
                    .frame(width: 60, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                Spacer()
                ShimmerView()
                    .frame(width: 100, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(WalletTheme.cardPadding)
        .glassCard()
    }

    // MARK: - Error Card

    private func errorCard(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(WalletTheme.destructive.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(WalletTheme.destructive)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Something went wrong")
                    .font(.system(size: 15, weight: .semibold))
                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: WalletTheme.cardRadius, style: .continuous)
                .fill(WalletTheme.destructive.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: WalletTheme.cardRadius, style: .continuous)
                .stroke(WalletTheme.destructive.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: WalletSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Summary")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text(summary.chain.symbol)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        WalletTheme.accentPrimary.opacity(0.12),
                                        WalletTheme.accentSecondary.opacity(0.08)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundStyle(WalletTheme.accentPrimary)
            }

            // Address row with copy
            VStack(alignment: .leading, spacing: 8) {
                infoRow("Address", summary.address, monospaced: true)
                Button {
                    UIPasteboard.general.string = summary.address
                    Haptics.success()
                    showCopiedToast()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text("Copy Address")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(WalletTheme.accentPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(WalletTheme.accentPrimary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Copy wallet address to clipboard")
            }

            divider
            infoRow("Chain", summary.chain.rawValue)
            divider

            // Balance with emphasis
            HStack(alignment: .firstTextBaseline) {
                Text("Balance")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(summary.nativeBalance)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [WalletTheme.accentPrimary, WalletTheme.accentTertiary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: summary.nativeBalance)
            }
        }
        .padding(WalletTheme.cardPadding)
        .glassCard()
    }

    // MARK: - Tokens Card

    private func tokensCard(_ tokens: [TokenBalance]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tokens")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("\(tokens.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
            }

            if tokens.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.system(size: 20))
                            .foregroundStyle(.quaternary)
                        Text("No tokens found")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(tokens.enumerated()), id: \.element.id) { index, token in
                        tokenRow(token, index: index)
                    }
                }
            }
        }
        .padding(WalletTheme.cardPadding)
        .glassCard()
    }

    private func tokenRow(_ token: TokenBalance, index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                tokenColor(for: index).opacity(0.18),
                                tokenColor(for: index).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text(String(token.symbol.prefix(1)))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(tokenColor(for: index))
            }
            .accessibilityHidden(true)

            Text(token.symbol)
                .font(.system(size: 15, weight: .semibold))

            Spacer()

            Text(token.amount)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(token.symbol): \(token.amount)")
    }

    // MARK: - Empty State

    private var emptyStateCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(WalletTheme.accentPrimary.opacity(0.06))
                    .frame(width: 64, height: 64)
                Image(systemName: "wallet.pass")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(WalletTheme.accentPrimary.opacity(0.5))
            }
            .accessibilityHidden(true)

            Text("No wallet loaded")
                .font(.system(size: 17, weight: .semibold))

            Text("Enter an address, pick a network,\nand tap \"Load Wallet\".")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: WalletTheme.cardRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: WalletTheme.cardRadius, style: .continuous)
                .strokeBorder(
                    WalletTheme.borderSubtle,
                    style: StrokeStyle(lineWidth: 1, dash: [CGFloat(6), CGFloat(4)])
                )
        )
    }

    // MARK: - Helpers

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.2))
            .frame(height: 0.5)
    }

    private func infoRow(_ title: String, _ value: String, monospaced: Bool = false, emphasize: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(monospaced ? .system(size: 13, design: .monospaced) : .system(size: 14))
                .fontWeight(emphasize ? .semibold : .regular)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private func shortAddress(_ value: String) -> String {
        guard value.count > 12 else { return value }
        let start = value.prefix(6)
        let end = value.suffix(4)
        return "\(start)...\(end)"
    }

    private func tokenColor(for index: Int) -> Color {
        let palette: [Color] = [
            WalletTheme.accentPrimary,
            WalletTheme.accentTertiary,
            WalletTheme.accentSecondary,
            Color(red: 0.96, green: 0.45, blue: 0.45),
            Color(red: 0.95, green: 0.72, blue: 0.20)
        ]
        return palette[index % palette.count]
    }

    private func showCopiedToast() {
        copiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            copiedToast = false
        }
    }
}

// MARK: - Glass Card Modifier

private struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: WalletTheme.cardRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WalletTheme.cardRadius, style: .continuous)
                    .stroke(WalletTheme.borderLight, lineWidth: 0.5)
            )
    }
}

private extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

// MARK: - Card Entrance Animation Modifier

private struct CardEntranceModifier: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.78)
                    .delay(Double(index) * 0.08),
                value: appeared
            )
    }
}

private extension View {
    func cardEntrance(index: Int, appeared: Bool) -> some View {
        modifier(CardEntranceModifier(index: index, appeared: appeared))
    }
}

// MARK: - Shimmer Effect

private struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color(.tertiarySystemFill))
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: phase)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
    }
}

#Preview {
    WalletViewerScreen()
}
