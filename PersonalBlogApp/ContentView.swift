import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = BlogViewModel()

    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ArticlesView(viewModel: viewModel)
                .tabItem {
                    Label("Articles", systemImage: "newspaper.fill")
                }

            AboutView(viewModel: viewModel)
                .tabItem {
                    Label("About", systemImage: "person.fill")
                }
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    ContentView()
}
