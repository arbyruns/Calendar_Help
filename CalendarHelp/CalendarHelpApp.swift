//
//  CalendarHelpApp.swift
//  CalendarHelp
//
//  Created by robevans on 9/4/21.
//

import SwiftUI

@main
struct CalendarHelpApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView(calendar: Calendar(identifier: .gregorian))
        }
    }
}
