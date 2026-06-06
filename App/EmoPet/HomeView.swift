import EmoPetKit
import EmoPetPersistence
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showBackup = false

    private var lang: PetLanguage { appState.uiLanguage }

    var body: some View {
        NavigationStack {
            TuscanyLivingRoomView()
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            if let pets = appState.session?.pets, pets.count > 1 {
                                Menu(L10n.text("menu.switchPet", language: lang)) {
                                    ForEach(pets) { p in
                                        Button(p.adoption.petName) {
                                            appState.switchPet(to: p.id)
                                        }
                                    }
                                }
                            }
                            if appState.canAdoptMore {
                                Button(L10n.text("button.adoptAnother", language: lang)) {
                                    appState.phase = .adoption
                                }
                            }
                            Button(L10n.text("menu.backup", language: lang)) { showBackup = true }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary.opacity(0.85))
                        }
                    }
                }
                .sheet(isPresented: $showBackup) {
                    BackupView()
                }
        }
    }
}

struct BackupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("所有数据保存在本地，可通过 JSON 文件导出/导入。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ShareLink(item: exportURL, preview: SharePreview("EmoPet 备份"))
                Button("关闭") { dismiss() }
            }
            .padding()
            .navigationTitle("数据备份")
        }
    }

    private var exportURL: URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("emopet_backup.json")
        if let store = try? LocalDataStore.defaultStore(),
           let session = appState.session,
           let data = try? store.exportBackup(session: session) {
            try? data.write(to: url)
        }
        return url
    }
}
