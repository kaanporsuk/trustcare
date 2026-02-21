import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var profileVM: ProfileViewModel

    @Binding var selectedTab: Int

    @State private var avatarItem: PhotosPickerItem?
    @State private var showAvatarOptions: Bool = false
    @State private var showPhotoPicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var capturedImage: UIImage?
    @State private var showEditProfile: Bool = false
    @State private var showProfileSavedToast: Bool = false
    @State private var showAvatarUpdatedToast: Bool = false
    @State private var showLogoutConfirm: Bool = false
    @State private var showErrorAlert: Bool = false

    init(selectedTab: Binding<Int> = .constant(2)) {
        _selectedTab = selectedTab
    }

    var body: some View {
        ScrollView {
            if profileVM.isLoading && profileVM.profile == nil {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                VStack(spacing: AppSpacing.lg) {
                    headerSection
                    referralSection
                    statsSection
                    menuSection
                    footerSection
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .dismissKeyboardOnTap()
        .task {
            await profileVM.loadProfile()
            await profileVM.loadReviews()
            await profileVM.loadNotificationCount()
        }
        .onChange(of: avatarItem) { _, newItem in
            Task {
                guard let newItem else { return }
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        let didUpdate = await profileVM.updateAvatar(image: image)
                        if didUpdate {
                            showAvatarUpdatedToast = true
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                showAvatarUpdatedToast = false
                            }
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                } catch {
                    profileVM.errorMessage = error.localizedDescription
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
        .onChange(of: capturedImage) { _, newImage in
            guard let newImage else { return }
            Task {
                let didUpdate = await profileVM.updateAvatar(image: newImage)
                if didUpdate {
                    showAvatarUpdatedToast = true
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        showAvatarUpdatedToast = false
                    }
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
        .onChange(of: profileVM.errorMessage) { _, newValue in
            showErrorAlert = newValue != nil
        }
        .onChange(of: showErrorAlert) { _, isShown in
            if !isShown {
                profileVM.errorMessage = nil
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $avatarItem, matching: .images)
        .sheet(isPresented: $showCameraPicker) {
            ImagePicker(sourceType: .camera, image: $capturedImage)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(
                fullName: profileVM.profile?.fullName ?? "",
                bio: profileVM.profile?.bio ?? "",
                phone: profileVM.profile?.phone ?? "",
                onSave: { fullName, bio, phone in
                    await profileVM.updateProfile(fullName: fullName, bio: bio, phone: phone)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    showProfileSavedToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        showProfileSavedToast = false
                    }
                }
            )
        }
        .confirmationDialog(String(localized: "Change Avatar"), isPresented: $showAvatarOptions) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(String(localized: "Take Photo")) {
                    showCameraPicker = true
                }
            }
            Button(String(localized: "Choose from Library")) {
                showPhotoPicker = true
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        }
        .overlay(alignment: .top) {
            if showProfileSavedToast {
                Text(String(localized: "Profile updated"))
                    .font(AppFont.caption)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.8))
                    .foregroundStyle(.white)
                    .cornerRadius(AppRadius.standard)
                    .padding(.top, AppSpacing.lg)
            } else if showAvatarUpdatedToast {
                Text(String(localized: "Photo updated"))
                    .font(AppFont.caption)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.8))
                    .foregroundStyle(.white)
                    .cornerRadius(AppRadius.standard)
                    .padding(.top, AppSpacing.lg)
            }
        }
        .alert(String(localized: "Error"), isPresented: $showErrorAlert) {
            Button(String(localized: "Done")) {
                showErrorAlert = false
                profileVM.errorMessage = nil
            }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
        .confirmationDialog(String(localized: "Log Out"), isPresented: $showLogoutConfirm) {
            Button(String(localized: "Log Out"), role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                authVM.signOut()
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Are you sure you want to log out?"))
        }
    }

    private var headerSection: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showAvatarOptions = true
            } label: {
                ZStack {
                    avatarView
                    if profileVM.isUpdatingAvatar {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Change Avatar"))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: AppSpacing.xs) {
                    Text(profileVM.profile?.displayName ?? String(localized: "Anonymous"))
                        .font(AppFont.title2)
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showEditProfile = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(AppColor.trustBlue)
                    }
                    .accessibilityLabel(String(localized: "Edit Profile"))
                }
                Text(memberSinceText)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var referralSection: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(String(localized: "Your code:"))
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            Text(profileVM.profile?.referralCode ?? "-")
                .font(.system(.caption, design: .monospaced))
            Spacer()
            Button {
                UIPasteboard.general.string = profileVM.profile?.referralCode ?? ""
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: "doc.on.doc")
                    .foregroundStyle(AppColor.trustBlue)
            }
            .accessibilityLabel(String(localized: "Copy referral code"))
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }

    private var statsSection: some View {
        let totalReviews = profileVM.myReviews.count
        let verifiedCount = profileVM.myReviews.filter { $0.isVerified }.count
        let verifiedPercent = totalReviews == 0 ? 0 : Int((Double(verifiedCount) / Double(totalReviews)) * 100)

        return HStack(spacing: AppSpacing.md) {
            statCard(title: String(format: String(localized: "reviews_count"), totalReviews))
            statCard(title: String(format: String(localized: "verified_percentage"), verifiedPercent))
        }
    }

    private var menuSection: some View {
        VStack(spacing: AppSpacing.sm) {
            NavigationLink {
                MyReviewsView(selectedTab: $selectedTab)
                    .environmentObject(profileVM)
            } label: {
                menuRow(title: String(localized: "My Reviews"))
            }

            NavigationLink {
                SettingsView()
                    .environmentObject(profileVM)
            } label: {
                menuRow(title: String(localized: "Settings"))
            }

            NavigationLink {
                HelpSupportView()
            } label: {
                menuRow(title: String(localized: "Help & Support"))
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                menuRow(title: String(localized: "Privacy Policy"))
            }

            NavigationLink {
                TermsOfServiceView()
            } label: {
                menuRow(title: String(localized: "Terms of Service"))
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showLogoutConfirm = true
            } label: {
                menuRow(title: String(localized: "Log Out"), isDestructive: true)
            }
        }
    }

    private var footerSection: some View {
        Text(String(localized: "Version 1.0.0"))
            .font(AppFont.footnote)
            .foregroundStyle(.secondary)
    }

    private var avatarView: some View {
        Group {
            if let urlString = profileVM.avatarDisplayUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(let error):
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                        }
                        .onAppear {
                            print("❌ Avatar AsyncImage failed to load from: \(urlString)")
                            print("   Error: \(error.localizedDescription)")
                        }
                    @unknown default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
    }

    private func menuRow(title: String, isDestructive: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(AppFont.body)
                .foregroundStyle(isDestructive ? AppColor.error : .primary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground)
        .cornerRadius(AppRadius.card)
    }

    private func statCard(title: String) -> some View {
        Text(title)
            .font(AppFont.headline)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground)
            .cornerRadius(AppRadius.card)
    }

    private var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        if let date = profileVM.profile?.createdAt {
            return String(format: String(localized: "Member since %@"), formatter.string(from: date))
        }
        return String(localized: "Member since -")
    }
}
