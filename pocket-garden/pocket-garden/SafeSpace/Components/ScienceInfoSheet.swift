//
//  ScienceInfoSheet.swift
//  pocket-garden
//
//  Reusable component for displaying evidence-based information
//

import SwiftUI

struct ScienceInfoSheet: View {
    let title: String
    let summary: String
    let evidence: String
    let linkTitle: String
    let url: String
    let accentColor: Color
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why this exercise helps")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(.label))
                    
                    Text(summary)
                        .font(.body)
                        .foregroundStyle(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(evidence)
                        .font(.body)
                        .foregroundStyle(Color(.secondaryLabel))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Source")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(.label))
                        
                        if let urlObject = URL(string: url) {
                            Link(linkTitle, destination: urlObject)
                                .font(.subheadline)
                                .foregroundStyle(accentColor)
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)
                }
            }
        }
    }
}

#Preview {
    ScienceInfoSheet(
        title: "Science behind this",
        summary: "Box breathing pairs steady inhales, holds, and exhales. This kind of structured breath slows your breathing rate, nudges the body toward a parasympathetic (rest-and-digest) state, and gives your mind a simple rhythm to focus on instead of racing thoughts.",
        evidence: "A 2023 randomized controlled study from Stanford asked adults to practice 5 minutes per day of simple breathwork patterns (including box-style breathing) or mindfulness meditation for 1 month. Breathwork produced larger improvements in positive mood and greater reductions in physiological arousal than mindfulness alone.",
        linkTitle: "Balban et al., 2023 – Brief structured respiration practices enhance mood and reduce physiological arousal",
        url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC9873947/",
        accentColor: .blue
    )
}
