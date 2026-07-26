import SwiftUI

@main
struct StorageAtlasApp: App {
    @StateObject private var model = StorageModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 660)
                .background(WindowConfigurator(theme: model.theme))
                .task {
                    guard !OnboardingWindowController.isCompleted else { return }
                    try? await Task.sleep(for: .milliseconds(350))
                    OnboardingWindowController.shared.present(model: model)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Scan Folder…") {
                    model.chooseAndScan()
                }
                .keyboardShortcut("o")
            }
            CommandMenu("View") {
                Picker("Theme", selection: $model.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title).tag(theme)
                    }
                }
                Divider()
                Button("Replay Onboarding") {
                    OnboardingWindowController.shared.present(model: model)
                }
            }
        }
    }
}
