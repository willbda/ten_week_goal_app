//
//  HappyToHaveLivedApp.swift
//  Happy to Have Lived
//
//  Created by David Williams on 11/1/25.
//

import SwiftUI
import Database  // DatabaseBootstrap for initialization
import App

@main
struct HappyToHaveLivedApp: App {

    init() {
        // Initialize database and CloudKit sync
        DatabaseBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
