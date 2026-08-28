import SwiftUI

/// Shows the merged set of indexed shortcuts and imported profile entries.
struct ShortcutsBrowserView: View {
    @EnvironmentObject private var appModel: HotkeyAdamAppModel
    @State private var groups: [ShortcutGroup] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                if groups.isEmpty {
                    Text("No shortcuts indexed or imported yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(groups) { group in
                        ShortcutGroupView(group: group)
                    }
                }
            }
            .padding()
        }
        .task {
            groups = appModel.mergedShortcuts()
        }
    }
}

private struct ShortcutGroupView: View {
    let group: ShortcutGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.appName)
                .font(.headline)

            ForEach(group.shortcuts) { row in
                HStack {
                    Text(row.title)
                        .lineLimit(1)
                    Spacer()
                    Text(row.shortcut)
                        .foregroundStyle(.secondary)
                    SourceBadge(source: row.source)
                }
                .font(.callout)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SourceBadge: View {
    let source: ShortcutRow.Source

    var body: some View {
        Text(source == .indexed ? "indexed" : "profile")
            .font(.caption2)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(source == .indexed ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
            .clipShape(Capsule())
    }
}
