import SwiftUI
import SwiftData
import Inject

struct WorryTreeView: View {
    @ObserveInjection var inject
    
    let onComplete: () -> Void
    
    @State private var currentStep: WorryTreeStep = .identify
    @State private var worryText: String = ""
    @State private var canControl: Bool? = nil
    @State private var actionPlan: String = ""
    @State private var letGoReason: String = ""
    @State private var showHistory: Bool = false
    @State private var pandaFeedback: String? = nil
    @State private var isLoadingPanda: Bool = false
    @State private var hasRequestedPanda: Bool = false
    @State private var currentEntry: WorryTreeEntry? = nil
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorryTreeEntry.date, order: .reverse) private var previousEntries: [WorryTreeEntry]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.orange.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Worry Tree")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(stepDescription)
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)

                    // History button
                    HStack {
                        Spacer()
                        Button(action: { showHistory = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Previous worries")
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(Color.cardBackground)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 24)
                    }
                    
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(WorryTreeStep.allCases, id: \.self) { step in
                            Circle()
                                .fill(step.rawValue <= currentStep.rawValue ? Color.orange : Color.borderColor)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // Current step content
                    stepContent
                        .padding(.horizontal, 24)
                    
                    // Use less spacer when we're on the completion step so Panda's card sits higher
                    if currentStep == .complete {
                        Spacer().frame(height: 12)
                    } else {
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showHistory) {
            WorryTreeHistoryView(entries: previousEntries)
        }
        .enableInjection()
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .identify:
            identifyWorryView
        case .canControl:
            canControlView
        case .actionable:
            actionableView
        case .letGo:
            letGoView
        case .complete:
            completionView
        }
    }

    // MARK: - Persistence & Panda

    private func saveEntry() {
        let entry = WorryTreeEntry(
            worryText: worryText,
            canControl: canControl,
            actionPlan: actionPlan.isEmpty ? nil : actionPlan,
            letGoNote: letGoReason.isEmpty ? nil : letGoReason,
            pandaFeedback: pandaFeedback
        )
        modelContext.insert(entry)
        currentEntry = entry
    }

    @MainActor
    private func generatePandaFeedbackIfNeeded() async {
        guard !hasRequestedPanda else { return }
        guard !worryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        hasRequestedPanda = true
        isLoadingPanda = true
        defer { isLoadingPanda = false }

        let historySummary = previousEntries.prefix(5).map { entry in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let dateString = formatter.string(from: entry.date)
            let snippet = entry.worryText.prefix(140)
            return "- [\(dateString)] \(snippet)"
        }.joined(separator: "\n")

        let result = await PandaWorryTreeService.shared.generate(
            worryText: worryText,
            canControl: canControl,
            actionPlan: actionPlan.isEmpty ? nil : actionPlan,
            letGoNote: letGoReason.isEmpty ? nil : letGoReason,
            historySummary: historySummary
        )

        pandaFeedback = result.text
        currentEntry?.pandaFeedback = result.text
    }
    
    private var identifyWorryView: some View {
        VStack(spacing: 24) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange.opacity(0.7))
                .padding(.top, 20)
            
            Text("What's worrying you?")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            
            TextEditor(text: $worryText)
                .frame(height: 150)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            Button(action: {
                withAnimation {
                    currentStep = .canControl
                }
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(worryText.isEmpty ? Color.gray : Color.orange)
                    )
            }
            .disabled(worryText.isEmpty)
            .buttonStyle(.plain)
        }
    }
    
    private var canControlView: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange.opacity(0.7))
                .padding(.top, 20)
            
            VStack(spacing: 12) {
                Text("Can you do anything about this right now?")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(worryText)
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    canControl = true
                    withAnimation {
                        currentStep = .actionable
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Yes, I can do something")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green)
                    )
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    canControl = false
                    withAnimation {
                        currentStep = .letGo
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("No, it's out of my control")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var actionableView: some View {
        VStack(spacing: 24) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.green.opacity(0.7))
                .padding(.top, 20)
            
            Text("What's your action plan?")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            
            TextEditor(text: $actionPlan)
                .frame(height: 150)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips for your action plan:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("Break it into small, specific steps")
                    bulletPoint("Set a realistic timeline")
                    bulletPoint("Identify what you need")
                }
            }
            .padding()
            .background(Color.cardBackground.opacity(0.5))
            .cornerRadius(12)
            
            Button(action: {
                saveEntry()
                withAnimation {
                    currentStep = .complete
                }
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(actionPlan.isEmpty ? Color.gray : Color.green)
                    )
            }
            .disabled(actionPlan.isEmpty)
            .buttonStyle(.plain)
        }
    }
    
    private var letGoView: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.blue.opacity(0.7))
                .padding(.top, 20)
            
            Text("Let it go")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)
            
            Text("This worry is outside your control right now. That's okay.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Ways to release this worry:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textSecondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    bulletPoint("Accept that you can't control everything")
                    bulletPoint("Focus on what you CAN control")
                    bulletPoint("Practice self-compassion")
                    bulletPoint("Return to the present moment")
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            
            Text("What helps you let go?")
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            
            TextEditor(text: $letGoReason)
                .frame(height: 100)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            Button(action: {
                saveEntry()
                withAnimation {
                    currentStep = .complete
                }
            }) {
                Text("Release This Worry")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue)
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.primaryGreen)
                .padding(.top, 8)
            
            VStack(spacing: 10) {
                Text("Well Done!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                if canControl == true {
                    Text("You have a plan to address your worry")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("You've acknowledged and released your worry")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image("panda_happy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                    
                    Text("Panda's suggestion")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textSecondary)
                }
                
                if let feedback = pandaFeedback {
                    Text(feedback)
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                } else if isLoadingPanda {
                    Text("Panda is thinking about a gentle plan for you…")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                } else {
                    Text("Remember: It's okay to have worries. What matters is how you respond to them.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
            )
            .padding(.horizontal, 24)
            
            Button(action: {
                onComplete()
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.primaryGreen)
                    )
            }
            .padding(.horizontal, 24)
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(.top, 24)
        .task {
            await generatePandaFeedbackIfNeeded()
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(Color.textSecondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case .identify:
            return "Name the worry that's on your mind"
        case .canControl:
            return "Decide if you can take action"
        case .actionable:
            return "Create a plan to address it"
        case .letGo:
            return "Practice acceptance and release"
        case .complete:
            return "You've processed your worry"
        }
    }
}

enum WorryTreeStep: Int, CaseIterable {
    case identify = 0
    case canControl = 1
    case actionable = 2
    case letGo = 3
    case complete = 4
}

struct WorryTreeHistoryView: View {
    let entries: [WorryTreeEntry]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if entries.isEmpty {
                    Section {
                        Text("No previous worries yet. Each time you complete a Worry Tree, it will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                } else {
                    ForEach(entries) { entry in
                        NavigationLink {
                            WorryTreeHistoryDetailView(entry: entry)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.worryText)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textPrimary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Previous Worries")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct WorryTreeHistoryDetailView: View {
    let entry: WorryTreeEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Worry")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textSecondary)

                    Text(entry.worryText)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                }

                if let plan = entry.actionPlan, !plan.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your plan")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textSecondary)

                        Text(plan)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                if let feedback = entry.pandaFeedback, !feedback.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image("panda_happy")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)

                            Text("Panda's suggestion")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textSecondary)
                        }

                        Text(feedback)
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Worry Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WorryTreeView {
        print("Worry tree completed")
    }
}
