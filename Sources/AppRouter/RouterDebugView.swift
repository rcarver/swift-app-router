//
//  File.swift
//  
//
//  Created by Ryan Carver on 1/14/21.
//

import SwiftUI

public struct RouterDebugView<Router: StackRouting>: View {

    public init(with router: Router) {
        self.router = router
    }

    @ObservedObject private var router: Router

    public var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Routers: \(router.routerStack.count)")
                .font(.subheadline)
            RouterListView(routers: router.routerStack)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
        .padding(8)
        .background(Color(.systemBackground).opacity(0.5))
        .border(Color.black)
        .padding(8)
    }

    struct RouterListView: View {
        var routers: [Router]
        var body: some View {
            ForEach(routers.indices) { index in
                RouterView(router: self.routers[index])
            }
        }
    }

    struct RouterView: View {
        @ObservedObject var router: Router
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(String(describing: router.objectAddress)).fontWeight(.bold)
                    + Text(" parent: ")
                    + Text(String(describing: router.parent?.objectAddress))
                Text(String(describing: router.route.base))
                    + Text(" pushed: ")
                    + Text(String(describing: router.route.pushed?.state))
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.1))
        }
    }
}
