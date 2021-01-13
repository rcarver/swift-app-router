# swift-app-router

A transparent, state-based, hierarchical router for SwiftUI.

## Example

A fully working router and infinite stack of views. The route state is simply an Int but anything can be used.

```swift
final class Router: AppRouting {

    init(state: Int, parent: Router? = nil) {
        self.route = Route(state)
        self.parent = parent
    }

    @Published var route: Route<Int>
    let parent: Router?

    func next(_ inc: Int) {
        state += inc
    }

    func makeChildRouter(state: Int) -> Router {
        Router(state: state, parent: self)
    }

    func makeContentView(state: Int) -> some View {
        CounterView(count: state)
    }
}

struct ContentView: View {

    var body: some View {
        NavigationView {
            RouterContentView(with: Router(state: 0))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct CounterView: View {

    var count: Int

    @EnvironmentObject private var router: Router

    var body: some View {
        VStack(spacing: 20) {
            Button(action: { router.next(1) }) { Text("Next +1") }
            Button(action: { router.next(2) }) { Text("Next +2") }
            Button(action: { router.pop() }) { Text("Back") }
            Button(action: { router.popToRoot() }) { Text("Top") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .buttonStyle(CustomButtonStyle())
        .background(Color.pick(count))
        .navigationBarTitle("Count is \(count)")
    }

    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(10)
                .foregroundColor(.primary)
                .background(Color(.systemBackground).opacity(configuration.isPressed ? 0.2 : 0.5))
                .cornerRadius(10)
        }
    }
}
```
