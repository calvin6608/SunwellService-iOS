//
//  SunwellServiceApp.swift
//  SunwellService
//
//  Created by Calvin on 2026/7/2.
//

import SwiftUI

@main
struct SunwellServiceApp: App {
    @StateObject private var session = AuthSession()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
