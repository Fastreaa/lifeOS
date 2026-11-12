import XCTest
@testable import LifeOS

@MainActor
final class SwiftDataProjectRepositoryTests: XCTestCase {
    private let created = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeRepository() throws -> any ProjectRepository {
        try AppDependencies(inMemory: true).projectRepository
    }

    func test_save_roundTripsAllFields() throws {
        let repository = try makeRepository()
        let project = try Project(name: "Universidad", symbolName: "graduationcap", color: .purple, now: created)

        try repository.save(project)

        XCTAssertEqual(try repository.fetchProjects(), [project])
    }

    func test_fetch_excludesDeleted() throws {
        let repository = try makeRepository()
        var deleted = try Project(name: "Viejo", now: created)
        deleted.markDeleted(at: created)
        try repository.save(try Project(name: "Activo", now: created.addingTimeInterval(1)))
        try repository.save(deleted)

        XCTAssertEqual(try repository.fetchProjects().map(\.name), ["Activo"])
    }

    func test_saveTwice_updatesWithoutDuplicating() throws {
        let repository = try makeRepository()
        var project = try Project(name: "Borrador", now: created)
        try repository.save(project)

        try project.update(name: "Trabajo", symbolName: "briefcase", color: .blue, now: created)
        try repository.save(project)

        XCTAssertEqual(try repository.fetchProjects(), [project])
    }
}
