import SwiftUI

struct HowToView: View {
    @Binding var route: RootView.Route

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("HOW TO PLAY")
                    .font(.bungee(30))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                StripDiagram()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)

                step(number: "1",
                     title: "Tap to flip",
                     color: .glassTeal,
                     text: "The ember ball is always falling. When it drops into the coloured strip near the bottom, tap anywhere to launch it back up — it flies toward your tap, so you aim and fire in one touch. Pop every glass orb to clear the wave.")

                step(number: "2",
                     title: "Ride the brink",
                     color: .emberOrange,
                     text: "The strip has three bands: ×1, ×2 and the thin red ×4 BRINK just above the drain. The deeper you dare to let the ball fall before flipping, the harder it launches and the more every orb is worth. Late is lucrative. Too late is gone.")

                step(number: "3",
                     title: "Chase the fever",
                     color: .brinkRed,
                     text: "Three BRINK flips ignite Fever — ten seconds of double score. You get three balls per run. When the last one drains, your score is posted to Game Center. One more run?")

                VStack(spacing: 12) {
                    MenuButton(title: "PLAY", prominent: true) { route = .game }
                    MenuButton(title: "BACK") { route = .home }
                }
                .padding(.top, 6)
            }
            .padding(28)
        }
        .background(Color.inkBackground)
    }

    private func step(number: String, title: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.bungee(24))
                .foregroundStyle(color)
                .frame(minWidth: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.bungee(17))
                    .foregroundStyle(.white)
                Text(text)
                    .font(.poppins(15))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A minature of the actual flip strip so the bands are seen before they're
/// read: ball falling in, three bands, drain below.
struct StripDiagram: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Circle()
                        .fill(LinearGradient(colors: [.white, .emberOrange], startPoint: .top, endPoint: .bottom))
                        .frame(width: 18, height: 18)
                        .shadow(color: .emberOrange.opacity(0.8), radius: 6)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
            .padding(.bottom, 6)

            band(label: "×1", color: Color(red: 0.35, green: 0.62, blue: 1), height: 42, note: "safe")
            band(label: "×2", color: .emberOrange, height: 30, note: "braver")
            band(label: "×4 BRINK", color: .brinkRed, height: 20, note: "all of it")

            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 2)
            Text("THE DRAIN")
                .font(.poppinsBold(10))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.top, 3)
        }
        .padding(.horizontal, 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Diagram of the flip strip: the ball falls into three stacked bands — times one at the top, times two below it, and the thin times four brink band just above the drain.")
    }

    private func band(label: String, color: Color, height: CGFloat, note: String) -> some View {
        ZStack {
            Rectangle()
                .fill(color.opacity(0.18))
                .overlay(Rectangle().fill(color.opacity(0.6)).frame(height: 1.5), alignment: .top)
            HStack {
                Text(label)
                    .font(.bungee(13))
                    .foregroundStyle(color)
                Spacer()
                Text(note)
                    .font(.poppins(11))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 10)
        }
        .frame(height: height)
    }
}
