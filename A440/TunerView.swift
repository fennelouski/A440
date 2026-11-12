import SwiftUI
import AVFoundation

@MainActor
@objc final class TonePlayer: NSObject, ObservableObject {
    /// One player shared by the phone UI and the AirPlay/external display, so both stay in sync.
    static let shared = TonePlayer()
    @Published @objc private(set) var activeInstrument = -1
    @Published var errorMessage: String?
    private var player: AVAudioPlayer?

    override init() {
        super.init()
        UserDefaults.standard.register(defaults: ["lastFile": "sineWave"])
        NotificationCenter.default.addObserver(self, selector: #selector(interrupted),
            name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stop),
            name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc func toggle(_ index: Int) {
        guard let instrument = A4Instrument(rawValue: index), (0...3).contains(index) else { return }
        if activeInstrument == index { stop(); return }
        stop()
        let file = A4InstrumentView(instrument: instrument).audioFileName
        do {
            guard let url = Bundle.main.url(forResource: file, withExtension: "wav") else {
                throw CocoaError(.fileNoSuchFile)
            }
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let next = try AVAudioPlayer(contentsOf: url)
            next.numberOfLoops = -1
            guard next.prepareToPlay(), next.play() else { throw CocoaError(.fileReadUnknown) }
            player = next
            activeInstrument = index
            errorMessage = nil
            UserDefaults.standard.set(file, forKey: "lastFile")
        } catch {
            stop()
            errorMessage = "The tone could not be played. Please try again."
        }
    }

    @objc func stop() {
        player?.stop()
        player = nil
        activeInstrument = -1
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    @objc private func interrupted(_ note: Notification) {
        if (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue {
            stop()
        }
    }
}

// Keep the existing custom instrument artwork and its animations.
private struct InstrumentArtwork: UIViewRepresentable {
    let index: Int
    let playing: Bool
    let legacy: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeUIView(context: Context) -> A4InstrumentView {
        let view = A4InstrumentView(instrument: A4Instrument(rawValue: index)!)
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        return view
    }

    func updateUIView(_ view: A4InstrumentView, context: Context) {
        view.isLegacyAppearance = legacy
        view.setPlaying(playing, animated: !reduceMotion)
        view.layer.speed = reduceMotion ? 0 : 1
    }
}

struct TunerView: View {
    @ObservedObject private var audio = TonePlayer.shared
    @AppStorage("legacyDesign") private var legacy = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    private let names = ["Piano", "Violin", "French Horn", "Sine Wave"]

    var body: some View {
        Group {
        #if os(visionOS)
        visionToneWorkspace
        #else
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("A440").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                            Text("Concert pitch reference").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            Toggle("Original 2015 design", isOn: $legacy)
                            Link("Privacy Policy", destination: URL(string: "https://nathanfennel.com/a440/privacy")!)
                            Link("Support", destination: URL(string: "https://nathanfennel.com/contact")!)
                        } label: {
                            Image(systemName: "ellipsis.circle").font(.title2).foregroundStyle(Color.primary).frame(width: 44, height: 44)
                        }.accessibilityLabel("Options")
                    }
                    HStack {
                        Text(audio.activeInstrument < 0 ? "Ready to tune" : "Playing \(names[audio.activeInstrument])")
                        Spacer()
                        Text("440 Hz").monospacedDigit()
                    }
                    .font(.headline)
                    .accessibilityElement(children: .combine)

                    // Wide, short space (iPhone Duo unfolded in landscape, any iPhone in landscape): one row of four.
                    // Even column counts keep the centre gap over the Duo's fold.
                    let wide = !typeSize.isAccessibilitySize && geometry.size.width > geometry.size.height * 1.25
                    let rows: CGFloat = wide ? 1 : 2
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: typeSize.isAccessibilitySize ? 1 : (wide ? 4 : 2)), spacing: 18) {
                        ForEach(0..<4) { index in
                            Button { audio.toggle(index) } label: {
                                InstrumentArtwork(index: index, playing: audio.activeInstrument == index, legacy: legacy)
                                    .frame(height: max(wide ? 160 : 220, min(380, (geometry.size.height - 230) / rows)))
                                    .overlay(alignment: .topTrailing) {
                                        if audio.activeInstrument == index {
                                            Image(systemName: "speaker.wave.2.fill")
                                                .padding(12).foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(names[index])
                            .accessibilityValue(audio.activeInstrument == index ? "Playing" : "Stopped")
                            .accessibilityHint("Tap to play or stop the 440 hertz tone.")
                        }
                    }
                    if audio.activeInstrument >= 0 {
                        Button("Stop playback", systemImage: "stop.fill", action: audio.stop)
                            .buttonStyle(.borderedProminent).controlSize(.large)
                    }
                    Text("Tap an instrument to play. Tap again to stop.\nShake to compare with the original design.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }
                .padding(24).frame(maxWidth: 900).frame(maxWidth: .infinity)
            }
            .background(LinearGradient(colors: [Color(uiColor: .a4BackgroundTop()), Color(uiColor: .a4BackgroundBottom())], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
        #endif
        }
        .tint(Color(uiColor: .a4BrandBottom()))
        .onChange(of: scenePhase) { _, phase in if phase != .active { audio.stop() } }
        .alert("Unable to play tone", isPresented: Binding(get: { audio.errorMessage != nil }, set: { if !$0 { audio.errorMessage = nil } })) {
            Button("OK") { audio.errorMessage = nil }
        } message: { Text(audio.errorMessage ?? "") }
    }

    #if os(visionOS)
    private var visionToneWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack(alignment: .firstTextBaseline, spacing: 24) {
                    Text("440").font(.system(size: 76, weight: .bold, design: .rounded)).monospacedDigit()
                    Text("Hz").font(.title)
                    Spacer(minLength: 16)
                    Label(audio.activeInstrument < 0 ? "Ready" : names[audio.activeInstrument], systemImage: audio.activeInstrument < 0 ? "tuningfork" : "waveform")
                        .font(.headline).fixedSize(horizontal: false, vertical: true)
                }.accessibilityElement(children: .combine)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 24)], spacing: 24) {
                    ForEach(0..<4) { index in
                        Button { audio.toggle(index) } label: {
                            InstrumentArtwork(index: index, playing: audio.activeInstrument == index, legacy: legacy)
                                .frame(height: 260)
                        }
                        .buttonStyle(.plain).hoverEffect()
                        .accessibilityLabel(names[index])
                        .accessibilityValue(audio.activeInstrument == index ? "Playing" : "Stopped")
                    }
                }
            }.padding(32)
        }
        .ornament(attachmentAnchor: .scene(.bottom)) {
            HStack(spacing: 20) {
                Button("Stop", systemImage: "stop.fill", action: audio.stop)
                    .disabled(audio.activeInstrument < 0).keyboardShortcut(".", modifiers: .command)
                Toggle("Original artwork", isOn: $legacy).toggleStyle(.button)
                Menu {
                    Link("Privacy Policy", destination: URL(string: "https://nathanfennel.com/a440/privacy")!)
                    Link("Support", destination: URL(string: "https://nathanfennel.com/contact")!)
                } label: { Label("About", systemImage: "info.circle") }
            }.buttonStyle(.bordered).controlSize(.large).padding(16).glassBackgroundEffect()
        }
    }
    #endif
}

#if os(iOS)
/// What an AirPlay/external screen shows: the same state as the phone, laid out to fill that screen's aspect ratio.
struct ExternalDisplayView: View {
    @ObservedObject private var audio = TonePlayer.shared
    @AppStorage("legacyDesign") private var legacy = false
    private let names = ["Piano", "Violin", "French Horn", "Sine Wave"]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let unit = min(size.width, size.height)
            let pad = unit * 0.06
            let gap = unit * 0.035
            let headerHeight = unit * 0.16
            let columns = size.width >= size.height ? 4 : 2
            let rows = 4 / columns
            let gridWidth = size.width - pad * 2
            let gridHeight = size.height - pad * 2 - headerHeight - gap
            // Cards keep a 4:5 shape and shrink to whichever dimension runs out first.
            let cardWidth = min((gridWidth - gap * CGFloat(columns - 1)) / CGFloat(columns),
                                (gridHeight - gap * CGFloat(rows - 1)) / CGFloat(rows) * 0.8)
            let playing = audio.activeInstrument

            VStack(spacing: gap) {
                HStack(alignment: .firstTextBaseline) {
                    Text("A440").font(.system(size: unit * 0.09, weight: .bold, design: .rounded))
                    Spacer()
                    Text(playing < 0 ? "Ready to tune" : "Playing \(names[playing])")
                        .font(.system(size: unit * 0.045, weight: .semibold, design: .rounded))
                    Text("· 440 Hz").monospacedDigit()
                        .font(.system(size: unit * 0.045, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(height: headerHeight)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(cardWidth), spacing: gap), count: columns), spacing: gap) {
                    ForEach(0..<4) { index in
                        InstrumentArtwork(index: index, playing: playing == index, legacy: legacy)
                            .frame(width: cardWidth, height: cardWidth * 1.25)
                            .scaleEffect(playing == index ? 1.05 : 1)
                            .opacity(playing < 0 || playing == index ? 1 : 0.5)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding(pad)
            .animation(.easeInOut(duration: 0.25), value: playing)
        }
        .foregroundStyle(Color.primary)
        .background(LinearGradient(colors: [Color(uiColor: .a4BackgroundTop()), Color(uiColor: .a4BackgroundBottom())], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
    }
}

@objc(A440ExternalSceneDelegate) final class ExternalSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: ExternalDisplayView())
        window.isHidden = false
        self.window = window
    }
}

// Scene lifecycle: required on iOS 27, and the window tracks the scene's live size on iPhone Duo fold/unfold.
@objc(A440SceneDelegate) final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = TunerViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

@objc final class TunerViewController: UIViewController {
    private let hosting = UIHostingController(rootView: TunerView())
    @objc init() { super.init(nibName: nil, bundle: nil) }
    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(hosting)
        hosting.view.frame = view.bounds
        hosting.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hosting.view)
        hosting.didMove(toParent: self)
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("Use init()") }
    override var canBecomeFirstResponder: Bool { true }
    override func viewDidAppear(_ animated: Bool) { super.viewDidAppear(animated); becomeFirstResponder() }
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let defaults = UserDefaults.standard
            defaults.set(!defaults.bool(forKey: "legacyDesign"), forKey: "legacyDesign")
        } else { super.motionEnded(motion, with: event) }
    }
}
#endif
