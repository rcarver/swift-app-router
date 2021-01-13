# swift-app-router

A transparent, state-based, hierarchical router for SwiftUI.

## Example

A fully working router and infinite stack of views. The route state is simply an Int but anything can be used.

```
struct ContentView: View {

    var body: some View {
        NavigationView {
            RouterContentView(with: Router(route: 0))
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

final class Router: AppRoutable {

    init(route: Int, parent: Router? = nil) {
        self.state = RouteState(route)
        self.parent = parent
    }

    @Published var state: RouteState<Int>
    let parent: Router?

    func next(_ inc: Int) {
        push(route: route + inc)
    }

    func makeChildRouter(route: Int) -> Router {
        Router(route: route, parent: self)
    }

    func makeContentView(route: Int) -> some View {
        CounterView(count: route)
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
        .navigationBarTitle("Count is \(count)")
    }
}
```
