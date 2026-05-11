//
//  just_do_itApp.swift
//  just do it
//
//  Created by hanry li on 5/10/26.
//

import SwiftUI

@main
struct just_do_itApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
