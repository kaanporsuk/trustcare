import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var profileVM: ProfileViewModel

    @State private var avatarItem: PhotosPickerItem?
    @State private var showLogoutConfirm: Bool = false

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
        .task {
            await profileVM.loadProfile()
            await profileVM.loadReviews()
            await profileVM.loadNotificationCount()
        }
        .onChange(of: avatarItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else { return }
                await profileVM.updateAvatar(image: image)
            }
        }
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { profileVM.errorMessage != nil },
            set: { if !$0 { profileVM.errorMessage = nil } }
        )) {
            Button(String(localized: "Done")) {
                profileVM.errorMessage = nil
            }
        } message: {
            Text(profileVM.errorMessage ?? "")
        }
        .confirmationDialog(String(localized: "Log Out"), isPresented: $showLogoutConfirm) {
            Button(String(localized: "Log Out"), role: .destructive) {
                authVM.signOut()
            }
            Button(String(localized: "Cancel"), role: .cancel) { }
        } message: {
            Text(String(localized: "Are you sure you want to log out?"))
        }
    }

    private var headerSection: some View {
        HStack(spacing: AppSpacing.md) {
            PhotosPicker(selection: $avatarItem, matching: .images) {
                avatarView
            }
            .accessibilityLabel(String(localized: "Change Avatar"))

            VStack(alignment: .leading, spacing: 4) {
                Text(profileVM.profile?.displayName ?? String(localized: "Anonymous"))
                    .font(AppFont.title2)
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
                MyReviewsView()
            } label: {
                menuRow(title: String(localized: "My Reviews"))
            }

            NavigationLink {
                SettingsView()
            } label: {
                menuRow(title: String(localized: "Settings"))
            }

            Link(destination: URL(string: "mailto:support@trustcare.app")!) {
                menuRow(title: String(localized: "Help & Support"))
            }

            Link(destination: URL(string: "https://trustcare.app/privacy")!) {
                menuRow(title: String(localized: "Privacy Policy"))
            }

            Link(destination: URL(string: "https://trustcare.app/terms")!) {
                menuRow(title: String(localized: "Terms of Service"))
            }

            Button {
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
            if let urlString = profileVM.profile?.avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
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
