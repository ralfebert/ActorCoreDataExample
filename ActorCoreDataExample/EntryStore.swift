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
        self.entries = await self.store.allEntries
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

    func addEntry() async {
        let entry = Entry.create(in: self.objectContext)
        entry.value = self.maxValue + 1
        try! self.objectContext.save()
        await self.fireOnChange()
    }

    var allEntries: [Int] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let entries = try! self.objectContext.fetch(fetchRequest)
        return entries.map(\.value)
    }

    private var maxValue: Int {
        self.allEntries.max() ?? 0
    }

    func fireOnChange() async {
        await self.stateObserver?.onStoreChange()
    }
}
