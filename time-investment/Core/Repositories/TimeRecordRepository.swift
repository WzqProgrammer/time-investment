import Foundation
import CoreData

protocol TimeRecordRepository {
    func fetchAll() -> [TimeRecord]
    func save(_ record: TimeRecord)
    func update(_ record: TimeRecord)
    func delete(id: UUID)
    func observeChanges(_ handler: @escaping () -> Void)
}

final class InMemoryTimeRecordRepository: TimeRecordRepository {
    private var records: [TimeRecord] = []
    private var observers: [UUID: () -> Void] = [:]

    func fetchAll() -> [TimeRecord] {
        records.sorted { $0.startTime > $1.startTime }
    }

    func save(_ record: TimeRecord) {
        records.append(record)
        notifyObservers()
    }

    func update(_ record: TimeRecord) {
        guard let index = records.firstIndex(where: { $0.id == record.id }) else { return }
        records[index] = record
        notifyObservers()
    }

    func delete(id: UUID) {
        records.removeAll { $0.id == id }
        notifyObservers()
    }

    func observeChanges(_ handler: @escaping () -> Void) {
        observers[UUID()] = handler
    }

    private func notifyObservers() {
        observers.values.forEach { $0() }
    }
}

@objc(CDTimeRecord)
final class CDTimeRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startTime: Date
    @NSManaged var endTime: Date
    @NSManaged var categoryRaw: String
    @NSManaged var appName: String?
    @NSManaged var websiteURL: String?
    @NSManaged var note: String
    @NSManaged var hourlyRateSnapshot: Double
    @NSManaged var efficiencyScore: Double
    @NSManaged var source: String
}

final class CoreDataTimeRecordRepository: TimeRecordRepository {
    private let container: NSPersistentContainer
    private let isStorageReady: Bool
    private(set) var storageWarningMessage: String?
    private var observers: [UUID: () -> Void] = [:]

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        do {
            container = try Self.buildContainer(model: model, inMemory: inMemory)
            isStorageReady = true
            storageWarningMessage = nil
        } catch {
            // Avoid app crash at launch. Fallback to in-memory storage if persistent store fails.
            if let fallback = try? Self.buildContainer(model: model, inMemory: true) {
                container = fallback
                isStorageReady = true
                storageWarningMessage = "持久化存储加载失败，已降级为临时内存存储，重启后数据可能丢失。"
                print("Core Data store failed, fallback to in-memory: \(error)")
            } else {
                container = NSPersistentContainer(name: "TimeInvestmentModel", managedObjectModel: model)
                isStorageReady = false
                storageWarningMessage = "存储系统初始化失败，当前不可写入数据。"
                print("Core Data and fallback store both failed: \(error)")
            }
        }
    }

    func fetchAll() -> [TimeRecord] {
        guard isStorageReady else { return [] }
        let request = CDTimeRecord.fetchRequestAll()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(CDTimeRecord.startTime), ascending: false)]
        guard let objects = try? container.viewContext.fetch(request) else { return [] }
        return objects.map {
            TimeRecord(
                id: $0.id,
                startTime: $0.startTime,
                endTime: $0.endTime,
                category: RecordCategory(rawValue: $0.categoryRaw) ?? .work,
                appName: $0.appName,
                websiteURL: $0.websiteURL,
                note: $0.note,
                hourlyRateSnapshot: $0.hourlyRateSnapshot,
                efficiencyScore: $0.efficiencyScore,
                source: $0.source
            )
        }
    }

    func save(_ record: TimeRecord) {
        guard isStorageReady else { return }
        let object = CDTimeRecord(context: container.viewContext)
        apply(record, to: object)
        persist()
    }

    func update(_ record: TimeRecord) {
        guard isStorageReady else { return }
        let request = CDTimeRecord.fetchRequestAll()
        request.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)
        guard let object = try? container.viewContext.fetch(request).first else { return }
        apply(record, to: object)
        persist()
    }

    func delete(id: UUID) {
        guard isStorageReady else { return }
        let request = CDTimeRecord.fetchRequestAll()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let object = try? container.viewContext.fetch(request).first {
            container.viewContext.delete(object)
            persist()
        }
    }

    func observeChanges(_ handler: @escaping () -> Void) {
        observers[UUID()] = handler
    }

    private func persist() {
        guard container.viewContext.hasChanges else { return }
        do {
            try container.viewContext.save()
            notifyObservers()
        } catch {
            container.viewContext.rollback()
        }
    }

    private func notifyObservers() {
        observers.values.forEach { $0() }
    }

    private func apply(_ record: TimeRecord, to object: CDTimeRecord) {
        object.id = record.id
        object.startTime = record.startTime
        object.endTime = record.endTime
        object.categoryRaw = record.category.rawValue
        object.appName = record.appName
        object.websiteURL = record.websiteURL
        object.note = record.note
        object.hourlyRateSnapshot = record.hourlyRateSnapshot
        object.efficiencyScore = record.efficiencyScore
        object.source = record.source
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name = "CDTimeRecord"
        entity.managedObjectClassName = NSStringFromClass(CDTimeRecord.self)

        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            return attr
        }

        entity.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("startTime", .dateAttributeType),
            attribute("endTime", .dateAttributeType),
            attribute("categoryRaw", .stringAttributeType),
            attribute("appName", .stringAttributeType, optional: true),
            attribute("websiteURL", .stringAttributeType, optional: true),
            attribute("note", .stringAttributeType),
            attribute("hourlyRateSnapshot", .doubleAttributeType),
            attribute("efficiencyScore", .doubleAttributeType),
            attribute("source", .stringAttributeType)
        ]

        model.entities = [entity]
        return model
    }

    private static func buildContainer(model: NSManagedObjectModel, inMemory: Bool) throws -> NSPersistentContainer {
        enum ContainerBuildError: Error {
            case loadTimedOut
        }

        let container = NSPersistentContainer(name: "TimeInvestmentModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }

        let timeout = semaphore.wait(timeout: .now() + 5)
        if timeout == .timedOut {
            throw ContainerBuildError.loadTimedOut
        }
        if let loadError {
            throw loadError
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }
}

private extension CDTimeRecord {
    @nonobjc static func fetchRequestAll() -> NSFetchRequest<CDTimeRecord> {
        NSFetchRequest<CDTimeRecord>(entityName: "CDTimeRecord")
    }
}
