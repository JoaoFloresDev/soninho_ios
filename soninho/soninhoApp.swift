//
//  soninhoApp.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

@main
struct soninhoApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
