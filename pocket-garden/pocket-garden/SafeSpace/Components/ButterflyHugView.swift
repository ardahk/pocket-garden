import SwiftUI
import Inject

struct ButterflyHugView: View {
    @ObserveInjection var inject
    
    let duration: Int
    let onComplete: () -> Void
    
    @State private var currentSide: HugSide = .left
    @State private var cyclesCompleted = 0
    @State private var isActive = false
    @State private var showInfo = false
    @Environment(\.dismiss) private var dismiss
    
    private let cycleDuration: Double = 1.2
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.backgroundCream,
                    Color.indigo.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                ZStack {
                    VStack(spacing: 8) {
                        Text("Butterfly Hug")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(isActive ? "Tap your shoulders with the rhythm" : "Cross your arms like butterfly wings")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.textSecondary.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: { showInfo = true }) {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Butterfly visualization
                VStack(spacing: 16) {
                    humanDiagramView
                    
                    if isActive {
                        Text(currentSide == .left ? "Tap your left shoulder" : "Tap your right shoulder")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("\(cyclesCompleted) taps")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textPrimary)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 16) {
                    if !isActive {
                        instructionsView
                    }
                    
                    Button(action: isActive ? stopHug : startHug) {
                        Text(isActive ? "Feeling better?" : "Start Butterfly Hug")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(isActive ? Color.primaryGreen : Color.indigo)
                            )
                    }
                    .padding(.horizontal, 24)
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showInfo) {
            infoSheet
        }
        .onDisappear {
            cancelHug()
        }
        .enableInjection()
    }
    
    private var infoSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 48) .weight(.light))
                        .foregroundStyle(Color.indigo)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                    
                    Text("About the Butterfly Hug")
                        .font(.title2.bold())
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("Developed by Lucina Artigas during the aftermath of Hurricane Pauline in 1998, the Butterfly Hug is a form of Bilateral Stimulation (BLS) used to process trauma and induce calm.")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How it works")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text("• Stimulates both sides of the brain")
                        Text("• Helps regulate emotions")
                        Text("• Creates a sense of safety and grounding")
                    }
                    .foregroundStyle(Color.textSecondary)
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                    
                    Text("While tapping, breathe slowly and observe your thoughts, feelings, and physical sensations without judgment. Visualize them passing like clouds.")
                        .font(.body)
                        .italic()
                        .foregroundStyle(Color.textSecondary)
                    
                    Link("Read more at EMDR Foundation", destination: URL(string: "https://emdrfoundation.org/toolkit/butterfly-hug.pdf")!)
                        .font(.subheadline)
                        .foregroundStyle(Color.indigo)
                        .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showInfo = false
                    }
                }
            }
            .background(Color.backgroundCream)
        }
    }
    
    private var humanDiagramView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.indigo.opacity(isActive ? 0.35 : 0.18),
                            Color.indigo.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 140
                    )
                )
                .frame(width: 240, height: 240)
            
            // Body/Torso
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.cardBackground)
                .frame(width: 160, height: 180)
                .offset(y: 40)
            
            // Head
            Circle()
                .fill(Color.cardBackground)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.indigo.opacity(0.25), lineWidth: 2)
                )
                .offset(y: -60)
                .zIndex(1)
            
            armView(side: .left, isActive: currentSide == .left && isActive)
                .zIndex(2)
            armView(side: .right, isActive: currentSide == .right && isActive)
                .zIndex(2)
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
    }
    
    private func armView(side: HugSide, isActive: Bool) -> some View {
        let isLeft = side == .left
        
        return ZStack {
            // Arm
            Capsule()
                .fill(Color.indigo.opacity(isActive ? 0.9 : 0.55))
                .frame(width: 150, height: 32)
                .rotationEffect(.degrees(isLeft ? -35 : 35))
                .offset(x: isLeft ? -20 : 20, y: 20)
            
            // Hand/Tap Indicator
            Circle()
                .fill(Color.primaryGreen.opacity(isActive ? 0.8 : 0.4))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                )
                .scaleEffect(isActive ? 1.12 : 1.0)
                .offset(x: isLeft ? -65 : 65, y: -5)
                .animation(.easeInOut(duration: 0.28), value: isActive)
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image("panda_supportive")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                
                Text("Cross your arms and place hands on opposite shoulders")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
            )
            
            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Sit or stand comfortably")
                bulletPoint("Cross your arms like butterfly wings on your shoulders")
                bulletPoint("Tap left–right with the rhythm and breathe slowly")
            }
            .padding()
            .background(Color.cardBackground.opacity(0.5))
            .cornerRadius(12)
        }
        .padding(.horizontal, 24)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(Color.textSecondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func startHug() {
        isActive = true
        cyclesCompleted = 0
        startCycle()
    }
    
    private func stopHug() {
        cancelHug()
        onComplete()
        dismiss()
    }
    
    private func cancelHug() {
        isActive = false
    }
    
    private func startCycle() {
        guard isActive else { return }
        
        currentSide = .left
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        cyclesCompleted += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + cycleDuration / 2) {
            guard self.isActive else { return }
            self.currentSide = .right
            generator.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + self.cycleDuration / 2) {
                self.startCycle()
            }
        }
    }
    
}

enum HugSide {
    case left, right
}

#Preview {
    ButterflyHugView(duration: 2) {
        print("Butterfly hug completed")
    }
}
