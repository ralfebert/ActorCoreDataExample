import CoreData
import Foundation

@objc(Entry)
public class Entry: NSManagedObject, Identifiable {
    static let entityName = "Entry"

    public static func create(in ctx: NSManagedObjectContext) -> Entry {
        NSEntityDescription.insertNewObject(forEntityName: Self.entityName, into: ctx) as! Entry
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        let request = NSFetchRequest<Entry>(entityName: Entry.entityName)
        return request
    }

    @NSManaged public var value: Int
}
