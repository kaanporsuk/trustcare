import SwiftUI
import MapKit

private struct RehberPayload: Decodable {
    let v: Int
    let recommended_entity_ids: [String]
    let urgency: String
    let follow_up_questions: [String]?

    private enum CodingKeys: String, CodingKey {
        case v
        case recommended_entity_ids
        case urgency
        case follow_up_questions
    }

    init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: CodingKeys.self)

        v = (try? container?.decodeIfPresent(Int.self, forKey: .v)) ?? 1
        recommended_entity_ids = (try? container?.decodeIfPresent([String].self, forKey: .recommended_entity_ids)) ?? []
        follow_up_questions = try? container?.decodeIfPresent([String].self, forKey: .follow_up_questions)

        let rawUrgency = ((try? container?.decodeIfPresent(String.self, forKey: .urgency)) ?? "low")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let allowedUrgencies = Set(["low", "medium", "high", "emergency"])
        urgency = allowedUrgencies.contains(rawUrgency) ? rawUrgency : "low"
    }
}

private struct ParsedAssistantMessage {
    let displayText: String
    let payload: RehberPayload?
}

struct RehberChatView: View {
    @ObservedObject var viewModel: RehberViewModel
    @Binding var showChat: Bool
    @ObservedObject private var specialtyService = SpecialtyService.shared
    @EnvironmentObject private var appRouter: AppRouter
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.locale) private var locale
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var taxonomyLabelsByEntityID: [String: String] = [:]
    @State private var validatedCanonicalIDsByMessageID: [UUID: [String]] = [:]

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    persistentInfoBar
                    RehberPlusBannerCard()
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: AppSpacing.sm) {
                                if !viewModel.isLoading && viewModel.messages.isEmpty {
                                    emptyState
                                } else if viewModel.isLoading && viewModel.messages.isEmpty {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, AppSpacing.md)
                                }

                                ForEach(viewModel.messages) { message in
                                    messageRow(message)
                                        .id(message.id)
                                }

                                if viewModel.isLoading && !viewModel.messages.isEmpty {
                                    typingIndicator
                                        .id("typing")
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.md)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: viewModel.isLoading) { _, _ in
                            scrollToBottom(proxy: proxy)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppFont.footnote)
                            .foregroundStyle(Color.tcCoral)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppSpacing.md)
                    }

                    usageCounter

                    inputBar
                }
                .background(Color.tcBackground)
                .navigationTitle(Text(tcKey: "tab_guide", fallback: "Guide"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            Task {
                                await viewModel.closeCurrentSession()
                                showChat = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(tcKey: "rehber_sessions", fallback: "Sessions")
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(tcString("rehber_new_short", fallback: "New")) {
                            Task {
                                await viewModel.closeCurrentSession()
                                viewModel.startNewChat()
                            }
                        }
                    }
                }

                if viewModel.showEmergencyCard {
                    EmergencyCardView {
                        viewModel.dismissEmergencyCard()
                    }
                    .transition(.opacity)
                    .zIndex(10)
                }
            }
            .task {
                if specialtyService.specialties.isEmpty {
                    await specialtyService.loadSpecialties()
                }
                await preloadTaxonomyLabelsForAssistantPayloads()
                await validateCanonicalPayloadsForAssistantMessages()
            }
            .task(id: viewModel.messages.count) {
                await preloadTaxonomyLabelsForAssistantPayloads()
                await validateCanonicalPayloadsForAssistantMessages()
            }
            .task(id: locale.identifier) {
                taxonomyLabelsByEntityID = [:]
                validatedCanonicalIDsByMessageID = [:]
                await preloadTaxonomyLabelsForAssistantPayloads()
                await validateCanonicalPayloadsForAssistantMessages()
            }
        }
    }

    private var persistentInfoBar: some View {
        HStack(spacing: AppSpacing.xs) {
            Text("🔵")
            Text("rehber_info_bar")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.tcOcean.opacity(0.08))
    }

    private var usageCounter: some View {
        HStack {
            Text(String(localized: "rehber_usage_counter")) + Text(" \(viewModel.usageCount)")
                .font(AppFont.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.xs)
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.sm) {
                TextField("rehber_input_placeholder", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(AppFont.body)
                    .focused($isInputFocused)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(Color.tcBorder, lineWidth: 1)
                    )
                    .submitLabel(.send)
                    .onSubmit {
                        submitCurrentMessage()
                    }

                Button {
                    submitCurrentMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(canSubmitMessage ? Color.tcOcean : Color.tcBorder)
                        .clipShape(Circle())
                }
                .disabled(!canSubmitMessage)
            }
            if viewModel.sendCooldownRemainingSeconds > 0 {
                Text(String(format: "rehber_cooldown", viewModel.sendCooldownRemainingSeconds))
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.xs)
        .padding(.bottom, AppSpacing.md)
        .background(Color.tcBackground)
    }

    private var canSubmitMessage: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isLoading
            && viewModel.sendCooldownRemainingSeconds == 0
    }

    private func submitCurrentMessage() {
        guard canSubmitMessage else { return }
        let text = inputText
        inputText = ""
        Task {
            await viewModel.sendMessage(text)
        }
    }

    @ViewBuilder
    private func messageRow(_ message: RehberMessage) -> some View {
        let parsedAssistantMessage = message.role == "assistant" ? parseAssistantMessage(message.content) : nil
        let renderedText = parsedAssistantMessage?.displayText ?? message.content
        let canonicalEntityIDs = validatedCanonicalIDsByMessageID[message.id] ?? []
        let emergencyFromUrgency = parsedAssistantMessage?.payload?.urgency.lowercased() == "emergency"
        let isEmergencyMessage = message.wasEmergency || emergencyFromUrgency
        let infoStyleMessage = message.isFallback || message.isRateLimited

        VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: AppSpacing.xs) {
            HStack {
                if message.role == "user" { Spacer(minLength: 50) }

                if infoStyleMessage && message.role == "assistant" {
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)

                        Text(renderedText)
                            .font(AppFont.body)
                            .foregroundStyle(Color.primary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color(.systemGray5))
                    .cornerRadius(AppRadius.card)
                } else {
                    Text(renderedText)
                        .font(AppFont.body)
                        .foregroundStyle(message.role == "user" ? Color.white : Color.primary)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(message.role == "user" ? Color.tcOcean : Color(.systemGray6))
                        .cornerRadius(AppRadius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card)
                                .stroke(isEmergencyMessage ? Color.tcCoral : Color.clear, lineWidth: 2)
                        )
                }

                if message.role == "assistant" { Spacer(minLength: 50) }
            }
            
            // Emergency action card for emergency messages
            if message.role == "assistant", isEmergencyMessage {
                emergencyActionCard
            }

            if message.role == "assistant", message.isFallback {
                Button("rehber_try_again") {
                    viewModel.retryLastFailedMessage()
                }
                .font(AppFont.footnote)
                .foregroundStyle(Color.tcOcean)
                .padding(.leading, AppSpacing.xs)
            }

            if message.role == "assistant", !canonicalEntityIDs.isEmpty {
                canonicalSpecialtyPills(canonicalEntityIDs)
            } else if message.role == "assistant", let specialties = message.recommendedSpecialties, !specialties.isEmpty {
                specialtyCards(specialties)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == "user" ? .trailing : .leading)
        .onAppear {
            if message.role == "assistant", isEmergencyMessage {
                // Trigger heavy haptic feedback for emergency
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                if message.id == viewModel.messages.last?.id {
                    viewModel.showEmergencyCard = true
                }
            }
        }
    }
    
    private var emergencyActionCard: some View {
        Button {
            if let url = URL(string: "tel://112"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("rehber_call_emergency")
                            .font(AppFont.headline)
                            .foregroundStyle(.white)
                        
                        Text("112")
                            .font(AppFont.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.md)
                
                Text("rehber_emergency_danger")
                    .font(AppFont.footnote)
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)
            }
            .background(Color.tcCoral)
            .cornerRadius(AppRadius.card)
        }
        .buttonStyle(.plain)
    }

    private func specialtyCards(_ specialties: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(specialties, id: \.self) { specialty in
                Button {
                    NotificationCenter.default.post(name: .trustCareSwitchTab, object: 0)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(name: .trustCareApplySpecialtyFilter, object: specialty)
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: iconName(for: specialty))
                            .foregroundStyle(Color.tcOcean)
                        Text(specialty)
                            .font(AppFont.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("rehber_find_provider")
                            .font(AppFont.footnote)
                            .foregroundStyle(Color.tcOcean)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(Color.tcSurface)
                    .cornerRadius(AppRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button)
                            .stroke(Color.tcBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, AppSpacing.xs)
    }

    private func canonicalSpecialtyPills(_ specialtyIDs: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(specialtyIDs, id: \.self) { specialtyID in
                    Button {
                        isInputFocused = false
                        appRouter.routeToDiscover(entityID: specialtyID)
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                            Text(taxonomyLabelsByEntityID[specialtyID] ?? specialtyID)
                                .font(AppFont.footnote)
                                .lineLimit(1)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color.tcOcean)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(Color.tcSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.button)
                                .stroke(Color.tcBorder, lineWidth: 1)
                        )
                        .cornerRadius(AppRadius.button)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, AppSpacing.xs)
        }
    }

    private func parseAssistantMessage(_ content: String) -> ParsedAssistantMessage {
        let pattern = "(?is)```json\\s*([\\s\\S]*?)\\s*```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ParsedAssistantMessage(displayText: content, payload: nil)
        }

        let fullRange = NSRange(content.startIndex..<content.endIndex, in: content)
        let matches = regex.matches(in: content, options: [], range: fullRange)
        guard let lastMatch = matches.last else {
            return ParsedAssistantMessage(displayText: content, payload: nil)
        }

        guard let jsonRange = Range(lastMatch.range(at: 1), in: content) else {
            return ParsedAssistantMessage(displayText: content, payload: nil)
        }

        let jsonText = String(content[jsonRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let jsonData = jsonText.data(using: .utf8) else {
            return ParsedAssistantMessage(displayText: content, payload: nil)
        }

        guard let payload = try? JSONDecoder().decode(RehberPayload.self, from: jsonData) else {
            return ParsedAssistantMessage(displayText: content, payload: nil)
        }

        var displayText = content
        if let blockRange = Range(lastMatch.range, in: content) {
            displayText.removeSubrange(blockRange)
            displayText = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ParsedAssistantMessage(
            displayText: displayText.isEmpty ? content : displayText,
            payload: payload
        )
    }

    private func validateCanonicalPayloadsForAssistantMessages() async {
        for message in viewModel.messages where message.role == "assistant" {
            if validatedCanonicalIDsByMessageID[message.id] != nil {
                continue
            }

            let parsed = parseAssistantMessage(message.content)
            let rawIDs = parsed.payload?.recommended_entity_ids
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty } ?? []

            guard !rawIDs.isEmpty else {
                validatedCanonicalIDsByMessageID[message.id] = []
                continue
            }

            do {
                let validIDs = try await TaxonomyService.validateEntityIDs(rawIDs)
                validatedCanonicalIDsByMessageID[message.id] = validIDs
            } catch {
                validatedCanonicalIDsByMessageID[message.id] = []
            }
        }
    }

    private func preloadTaxonomyLabelsForAssistantPayloads() async {
        let entityIDs = allValidatedCanonicalEntityIDsInMessages()
        guard !entityIDs.isEmpty else { return }

        let unresolved = entityIDs.filter { taxonomyLabelsByEntityID[$0] == nil }
        guard !unresolved.isEmpty else { return }

        do {
            let labels = try await TaxonomyService.labelsByEntityID(
                entityIDs: unresolved,
                locale: currentLocaleCode()
            )
            taxonomyLabelsByEntityID.merge(labels) { _, new in new }
        } catch {
            return
        }
    }

    private func allValidatedCanonicalEntityIDsInMessages() -> [String] {
        var unique = Set<String>()

        for message in viewModel.messages where message.role == "assistant" {
            for entityID in validatedCanonicalIDsByMessageID[message.id] ?? [] {
                if !entityID.isEmpty {
                    unique.insert(entityID)
                }
            }
        }

        return Array(unique).sorted()
    }

    private func currentLocaleCode() -> String {
        if let languageCode = locale.language.languageCode?.identifier, !languageCode.isEmpty {
            return languageCode
        }
        let normalized = locale.identifier
            .components(separatedBy: ["-", "_"])
            .first?
            .lowercased() ?? "en"
        return normalized
    }

    private var typingIndicator: some View {
        HStack {
            TypingDotsView()
            Spacer(minLength: 50)
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("rehber_empty_state")
                    .font(AppFont.body)
                    .foregroundStyle(.secondary)
                Text("rehber_empty_state_sub")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)
            }

            if !starterPromptSpecialties.isEmpty {
                Text("rehber_start_guidance")
                    .font(AppFont.footnote)
                    .foregroundStyle(.secondary)

                VStack(spacing: AppSpacing.xs) {
                    ForEach(starterPromptSpecialties) { specialty in
                        Button {
                            Task {
                                await viewModel.sendMessage(starterPrompt(for: specialty))
                            }
                        } label: {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: specialty.iconName)
                                    .foregroundStyle(Color.tcOcean)
                                Text(specialty.resolvedName(using: localizationManager))
                                    .font(AppFont.body)
                                    .foregroundStyle(Color.tcTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.tcOcean)
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Color.tcBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.button)
                                    .stroke(Color.tcBorder, lineWidth: 1)
                            )
                            .cornerRadius(AppRadius.button)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tcSurface)
        .cornerRadius(AppRadius.card)
    }

    private var starterPromptSpecialties: [Specialty] {
        specialtyService.specialties
            .filter { $0.isPopular }
            .sorted { $0.displayOrder < $1.displayOrder }
            .prefix(4)
            .map { $0 }
    }

    private func starterPrompt(for specialty: Specialty) -> String {
        let name = specialty.resolvedName(using: localizationManager)
        let lang = localizationManager.effectiveLanguage.lowercased()
        if lang == "tr" {
            return "\(name) ile ilgili hangi doktora gitmeliyim?"
        }
        return "Can you guide me for \(name)?"
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if viewModel.isLoading {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            } else if let lastId = viewModel.messages.last?.id {
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(lastId, anchor: .bottom)
                }
            }
        }
    }

    private func iconName(for specialtyName: String) -> String {
        if let specialty = specialtyService.specialties.first(where: {
            $0.name.caseInsensitiveCompare(specialtyName) == .orderedSame
            || ($0.nameTr?.caseInsensitiveCompare(specialtyName) == .orderedSame)
        }) {
            return specialty.iconName
        }
        return "cross.case"
    }
}

private struct TypingDotsView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 6) {
            dot(delay: 0)
            dot(delay: 0.2)
            dot(delay: 0.4)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(Color(.systemGray6))
        .cornerRadius(AppRadius.card)
        .onAppear {
            isAnimating = true
        }
    }

    private func dot(delay: Double) -> some View {
        Circle()
            .fill(Color.secondary)
            .frame(width: 7, height: 7)
            .scaleEffect(isAnimating ? 1.0 : 0.6)
            .opacity(isAnimating ? 1 : 0.4)
            .animation(
                .easeInOut(duration: 0.6)
                    .repeatForever()
                    .delay(delay),
                value: isAnimating
            )
    }
}

struct EmergencyCardView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.tcCoral.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.lg) {
                Spacer()

                Text("rehber_emergency_title")
                    .font(AppFont.title1)
                    .foregroundStyle(.white)

                Text("rehber_emergency_subtitle")
                    .font(AppFont.headline)
                    .foregroundStyle(.white)

                Button {
                    if let url = URL(string: "tel://112"), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("rehber_call_112")
                        .font(AppFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red)
                        .cornerRadius(AppRadius.button)
                }

                Button {
                    let query = "Acil Servis".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Acil%20Servis"
                    if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("rehber_nearest_emergency")
                        .font(AppFont.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(AppRadius.button)
                }

                Spacer()

                Button(tcString("close_button", fallback: "Close")) {
                    onDismiss()
                }
                .font(AppFont.footnote)
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.bottom, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
    }
}
