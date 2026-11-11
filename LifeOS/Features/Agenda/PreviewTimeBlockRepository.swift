#if DEBUG
import Foundation

/// Repositorio en memoria para las vistas previas. Solo en desarrollo.
nonisolated final class PreviewTimeBlockRepository: TimeBlockRepository {
    private var storage: [UUID: TimeBlock] = [:]

    init(blocks: [TimeBlock] = []) {
        for block in blocks { storage[block.id] = block }
    }

    @MainActor
    func fetchBlocks(on day: LocalDay) throws -> [TimeBlock] {
        storage.values
            .filter { !$0.isDeleted && $0.day == day }
            .sorted { $0.startMinute < $1.startMinute }
    }

    @MainActor
    func save(_ block: TimeBlock) throws {
        storage[block.id] = block
    }

    static var sample: PreviewTimeBlockRepository {
        let today = LocalDay(.now, calendar: .current)
        let items: [(String, BlockKind, Int, Int)] = [
            ("Clase de cálculo", .classSession, 9 * 60, 11 * 60),
            ("Comida y descanso", .rest, 14 * 60, 15 * 60),
            ("Estudiar para el examen", .study, 16 * 60, 18 * 60),
            ("Gimnasio", .exercise, 17 * 60 + 30, 18 * 60 + 30),
        ]
        let blocks = items.compactMap { item -> TimeBlock? in
            try? TimeBlock(day: today, title: item.0, kind: item.1, startMinute: item.2, endMinute: item.3)
        }
        return PreviewTimeBlockRepository(blocks: blocks)
    }
}
#endif
