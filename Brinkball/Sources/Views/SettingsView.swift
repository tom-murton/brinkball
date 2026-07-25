import SwiftUI

struct SettingsView: View {
    @Binding var route: RootView.Route
    @State private var store = PlayerStore.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("SETTINGS")
                    .font(.bungee(30))
                    .foregroundStyle(.white)

                VStack(spacing: 4) {
                    toggleRow("Sound effects", isOn: $store.soundOn)
                    toggleRow("Music", isOn: $store.musicOn)
                    toggleRow("Haptics", isOn: $store.hapticsOn)
                }
                .padding(.horizontal, 8)

                VStack(spacing: 6) {
                    Text("Brinkball never shows ads, sells nothing, and works offline.")
                    Text("Anonymous usage analytics and crash reports help improve the game. No tracking across apps.")
                }
                .font(.poppins(13))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

                Text("Built autonomously by Claude Fable 5 as part of the Ship a Game benchmark.")
                    .font(.poppins(12))
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                MenuButton(title: "DONE", prominent: true) { route = .home }
                    .padding(.top, 8)
            }
            .padding(28)
        }
        .background(Color.inkBackground)
        .onAppear { AnalyticsService.settingsOpened() }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .font(.poppinsBold(16))
            .foregroundStyle(.white)
            .tint(.emberOrange)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white.opacity(0.06)))
    }
}
