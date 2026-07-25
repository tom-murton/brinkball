import SwiftUI

@main
struct BrinkballApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AnalyticsService.configure()
        Task { @MainActor in
            _ = PlayerStore.shared        // load persisted settings into Audio/Haptics first
            AudioPlayer.shared.start()
            GameCenterManager.shared.authenticate()
        }
        return true
    }
}

struct RootView: View {
    enum Route { case home, game, howTo, settings }
    @State private var route: Route = .home

    var body: some View {
        ZStack {
            Color.inkBackground.ignoresSafeArea()
            switch route {
            case .home:
                HomeView(route: $route)
                    .transition(.opacity)
            case .game:
                GameView(route: $route)
                    .transition(.opacity)
            case .howTo:
                HowToView(route: $route)
                    .transition(.opacity)
            case .settings:
                SettingsView(route: $route)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: routeKey)
    }

    private var routeKey: Int {
        switch route {
        case .home: 0
        case .game: 1
        case .howTo: 2
        case .settings: 3
        }
    }
}

extension Color {
    static let inkBackground = Color(red: 0.02, green: 0.02, blue: 0.05)
    static let brinkRed = Color(red: 1, green: 0.20, blue: 0.24)
    static let emberOrange = Color(red: 1, green: 0.62, blue: 0.18)
    static let glassTeal = Color(red: 0.25, green: 0.90, blue: 0.83)
    static let feverPink = Color(red: 1, green: 0.5, blue: 0.9)
}

extension Font {
    static func bungee(_ size: CGFloat) -> Font { .custom("Bungee-Regular", size: size) }
    static func poppins(_ size: CGFloat) -> Font { .custom("Poppins-Regular", size: size) }
    static func poppinsBold(_ size: CGFloat) -> Font { .custom("Poppins-Bold", size: size) }
}
