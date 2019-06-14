//
//  DataStorage.swift
//  Voice Recorder
//
//  Created by Egor on 6/14/19.
//  Copyright © 2019 Egor. All rights reserved.
//

import CoreData
import RxSwift
import RxCoreData

protocol DataStorage {

    func store<T>(_ entry: T) where T: Identifiable

    func loadEntries<T>(of type: T.Type) -> [T] where T: Identifiable

    func loadObservableEntries<T: Identifiable>(of type: T.Type) -> Observable<[T]>

    func delete(_ entry: Identifiable)
}

final class CoreDataStorage: DataStorage {

    static let shared = CoreDataStorage()

    let persistentContainer: NSPersistentContainer

    private lazy var managedObjectContext = persistentContainer.viewContext

    required init() {
        persistentContainer = NSPersistentContainer(name: "VoiceRecorder")
        persistentContainer.loadPersistentStores { _, error in
            guard let error = error else { return }
            print("Error loading persistent stores: \(error)")
        }
    }

    func store<T>(_ entry: T) where T: Identifiable {
        let object = Recording(context: managedObjectContext)
        object.id = entry.identifier
        object.data = try? JSONEncoder().encode(entry)
        try? managedObjectContext.save()
    }

    // MARK: Loading

    func loadEntries<T>(of type: T.Type) -> [T] where T: Identifiable {
        guard let recordings = try? managedObjectContext.fetch(Recording.fetchRequest()) as? [Recording] else {
            return []
        }
        return recordings
            .compactMap { $0.data }
            .compactMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    func loadObservableEntries<T>(of type: T.Type) -> Observable<[T]> where T: Identifiable {
        let request: NSFetchRequest<Recording> = Recording.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor.init(key: "id", ascending: false)]
        return managedObjectContext.rx
            .entities(fetchRequest: request)
            .map { recordings in
                recordings.compactMap { recording -> T? in
                    guard let data = recording.data else { return nil }
                    return try? JSONDecoder().decode(T.self, from: data)
                }
        }
    }

    // MARK: Deleting

    func delete(_ entry: Identifiable) {
        let request: NSFetchRequest<NSFetchRequestResult> = Recording.fetchRequest()
        let predicate = NSPredicate(format: "id == %@", entry.identifier)
        request.predicate = predicate

        let results = try? managedObjectContext.fetch(request) as? [Recording]

        results?.forEach(managedObjectContext.delete)
        try? managedObjectContext.save()
    }

    func drop() {
        guard
            let result = try? managedObjectContext.fetch(Recording.fetchRequest()),
            !result.isEmpty else {
                return // Already empty
        }
        result
            .compactMap { $0 as? NSManagedObject }
            .forEach(managedObjectContext.delete)
        try? managedObjectContext.save()
    }
}
