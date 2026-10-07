import SwiftData
import SwiftUI

struct PlaylistsView: View {
    let onPremiumRequired: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var catalog: CatalogStore
    @EnvironmentObject private var entitlements: EntitlementStore
    @Query(sort: \SoundPlaylist.updatedAt, order: .reverse) private var playlists: [SoundPlaylist]
    @State private var newPlaylistName = ""
    @State private var isCreatingPlaylist = false
    @State private var selectedCard: SoundCard?
    @State private var localError: String?

    var body: some View {
        List {
            if !entitlements.hasPremium {
                Section {
                    ContentUnavailableView(
                        "Premium playlists",
                        systemImage: "text.badge.plus",
                        description: Text("Build your own sets of favorite sounds with Premium.")
                    )
                    Button("See Premium options", action: onPremiumRequired)
                }
            } else if playlists.isEmpty {
                ContentUnavailableView(
                    "No playlists yet",
                    systemImage: "music.note.list",
                    description: Text("Create a collection for playtime, greetings, or calm moments.")
                )
            } else {
                ForEach(playlists) { playlist in
                    Section {
                        ForEach(playlist.soundIDs.compactMap { catalog.card(withID: $0) }) { card in
                            Button {
                                selectedCard = card
                            } label: {
                                Label(card.title, systemImage: card.category.systemImage)
                            }
                            .foregroundStyle(.primary)
                        }
                        .onDelete { offsets in
                            var ids = playlist.soundIDs
                            ids.remove(atOffsets: offsets)
                            playlist.soundIDs = ids
                            saveContext()
                        }
                    } header: {
                        HStack {
                            Text(playlist.name)
                            Spacer()
                            Button(role: .destructive) {
                                modelContext.delete(playlist)
                                saveContext()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityLabel("Delete \(playlist.name)")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar {
            if entitlements.hasPremium {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreatingPlaylist = true
                    } label: {
                        Label("New Playlist", systemImage: "plus")
                    }
                }
            }
        }
        .alert("New Playlist", isPresented: $isCreatingPlaylist) {
            TextField("Playlist name", text: $newPlaylistName)
            Button("Cancel", role: .cancel) { newPlaylistName = "" }
            Button("Create") { createPlaylist() }
                .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .sheet(item: $selectedCard) { card in
            SoundDetailView(card: card)
                .presentationDetents([.medium, .large])
        }
        .alert("Couldn’t save playlist", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localError ?? "Please try again.")
        }
    }

    private func createPlaylist() {
        let name = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(SoundPlaylist(name: String(name.prefix(40))))
        if saveContext() {
            newPlaylistName = ""
        }
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            localError = error.localizedDescription
            return false
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { localError != nil },
            set: { if !$0 { localError = nil } }
        )
    }
}

struct PlaylistPickerView: View {
    let soundID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SoundPlaylist.updatedAt, order: .reverse) private var playlists: [SoundPlaylist]
    @State private var newPlaylistName = ""
    @State private var localError: String?

    var body: some View {
        NavigationStack {
            List {
                if playlists.isEmpty {
                    Text("Create your first playlist below.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(playlists) { playlist in
                        Button {
                            playlist.toggle(soundID: soundID)
                            saveContext()
                        } label: {
                            HStack {
                                Text(playlist.name)
                                Spacer()
                                if playlist.soundIDs.contains(soundID) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.purple)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Create and add") {
                    TextField("Playlist name", text: $newPlaylistName)
                    Button("Create Playlist") { createAndAdd() }
                        .disabled(newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Couldn’t save playlist", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localError ?? "Please try again.")
            }
        }
    }

    private func createAndAdd() {
        let name = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(SoundPlaylist(name: String(name.prefix(40)), soundIDs: [soundID]))
        if saveContext() {
            dismiss()
        }
    }

    @discardableResult
    private func saveContext() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            localError = error.localizedDescription
            return false
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { localError != nil },
            set: { if !$0 { localError = nil } }
        )
    }
}
