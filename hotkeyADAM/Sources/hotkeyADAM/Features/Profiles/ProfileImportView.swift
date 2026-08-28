import SwiftUI
import UniformTypeIdentifiers

/// Provides the "Import Profile…" UI: a file picker plus validation feedback.
struct ProfileImportView: View {
    var onImport: (URL) throws -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Import a shortcut profile")
                .font(.headline)

            Text("Choose a JSON profile file describing an application's shortcuts.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Choose Profile…") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [.json]
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.begin { response in
                    guard response == .OK, let url = panel.url else { return }
                    do {
                        try onImport(url)
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
