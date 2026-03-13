import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("What Jemmie Can Do")) {
                    HelpRow(
                        icon: "camera.fill",
                        color: .blue,
                        title: "Take Photos",
                        description: "Ask Jemmie to 'Help me look at this' or 'Take a photo'."
                    )
                    HelpRow(
                        icon: "location.fill",
                        color: .green,
                        title: "Fetch Location",
                        description: "Ask for your current location or get contextual info based on where you are."
                    )
                    HelpRow(
                        icon: "speaker.wave.3.fill",
                        color: .orange,
                        title: "Volume Button Input",
                        description: "When asked a yes/no question, you can answer silently using your volume buttons (Up for Yes, Down for No)."
                    )
                    HelpRow(
                        icon: "doc.on.clipboard.fill",
                        color: .gray,
                        title: "Copy to Clipboard",
                        description: "Ask Jemmie to copy text, addresses, or links to your device's clipboard."
                    )
                    HelpRow(
                        icon: "safari.fill",
                        color: .cyan,
                        title: "Open Links",
                        description: "Jemmie can automatically open URLs or map directions for you."
                    )
                    HelpRow(
                        icon: "bell.fill",
                        color: .red,
                        title: "Set Reminders & Alarms",
                        description: "Ask Jemmie to set a reminder or an alarm, and you will receive a notification."
                    )
                }
            }
            .navigationTitle("Actions Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct HelpRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HelpView()
}
