import SwiftUI

struct TemplatePickerView: View {
    let templates: [PoseTemplate]
    let selectedTemplateID: String?
    let onSelect: (PoseTemplate) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(templates) { template in
                    Button {
                        onSelect(template)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(LocalizedStringKey(template.displayNameKey))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if let subtitle = template.subtitleKey {
                                Text(LocalizedStringKey(subtitle))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(template.effectTags.joined(separator: " · "))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(width: 220, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(selectedTemplateID == template.id ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(selectedTemplateID == template.id ? Color.accentColor : Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

