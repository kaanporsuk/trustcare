import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var fullName: String
    @State private var bio: String
    @State private var phone: String
    @State private var isSaving: Bool = false

    let onSave: (String, String, String) async -> Void

    init(fullName: String, bio: String, phone: String, onSave: @escaping (String, String, String) async -> Void) {
        _fullName = State(initialValue: fullName)
        _bio = State(initialValue: bio)
        _phone = State(initialValue: phone)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Profile")) {
                    TextField(String(localized: "Full Name"), text: $fullName)
                    TextField(String(localized: "Phone"), text: $phone)
                        .keyboardType(.phonePad)
                    TextEditor(text: $bio)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(String(localized: "Edit Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .keyboardDoneToolbar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving || fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        await onSave(
            fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            bio.trimmingCharacters(in: .whitespacesAndNewlines),
            phone.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        isSaving = false
        dismiss()
    }
}
