import SwiftUI
import UIKit

struct ContentView: View {
    @State private var shareText: String? = nil
    @State private var isShowingShareSheet = false

    var body: some View {
        ZStack {
            Color(red: 0.93, green: 0.95, blue: 0.97)
                .ignoresSafeArea()

            WebViewContainer(onShare: { text in
                self.shareText = text
                self.isShowingShareSheet = true
                
                // Native iOS Haptic Feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            })
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let text = shareText {
                ActivityView(activityItems: [text])
            }
        }
    }
}

// Native iOS UIActivityViewController Bridge for Sharing
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {}
}
