import SwiftUI

struct ResultView: View {
    let score: Double
    let templateName: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("result.title")
                .font(.title2.bold())
            Text(templateName)
                .font(.headline)
            Text("result.score \(Int(score * 100))")
                .font(.body)
            Text("result.note")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

