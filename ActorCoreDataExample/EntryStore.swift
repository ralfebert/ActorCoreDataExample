import CoreData
import Foundation

@MainActor
class EntryModel: ObservableObject, EntryStoreObserver {
    let store = EntryStore()

    @Published var entries: [Int] = []

    init() {
        Task {
            await self.store.registerObserver(observer: self)
            await self.updateFromStore()
        }
    }

    func onStoreChange() async {
        await self.updateFromStore()
    }

    func updateFromStore() async {
        self.entries = await self.store.allEntries()
    }
}

protocol EntryStoreObserver {
    func onStoreChange() async
}

actor EntryStore {
    private var objectContext: NSManagedObjectContext
    private var persistentContainer: NSPersistentContainer
    private var stateObserver: EntryStoreObserver?

    init() {
        self.persistentContainer = NSPersistentContainer(name: "EntryStore")

        self.persistentContainer.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        self.objectContext = self.persistentContainer.newBackgroundContext()
    }

    func registerObserver(observer: EntryStoreObserver) async {
        self.stateObserver = observer
    }

    func performCoreDataOperation<T>(_ block: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            objectContext.perform {
                continuation.resume(returning: block())
            }
        }
    }

    func addEntry() async {
        let maxValue = await self.maxValue()
        await self.performCoreDataOperation {
            let entry = Entry.create(in: self.objectContext)
            entry.value = maxValue + 1
            try! self.objectContext.save()
        }
        await self.fireOnChange()
    }

    func allEntries() async -> [Int] {
        await self.performCoreDataOperation {
            let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
            let entries = try! self.objectContext.fetch(fetchRequest)
            return entries.map(\.value)
        }
    }

    private func maxValue() async -> Int {
        (await self.allEntries()).max() ?? 0
    }

    func fireOnChange() async {
        await self.stateObserver?.onStoreChange()
    }
}
