import SwiftData
import SwiftUI

@main
struct FitnessAppApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: AppSchema.schema)
            SampleDataSeeder.seedIfNeeded(in: container.mainContext)
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
