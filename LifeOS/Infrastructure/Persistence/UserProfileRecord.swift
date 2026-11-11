import Foundation
import SwiftData

/// Perfil del usuario en SwiftData. `nonisolated` por D-012.
@Model
nonisolated final class UserProfileRecord {
    @Attribute(.unique) var id: UUID
    var displayName: String?
    var dayStartMinute: Int
    var dayEndMinute: Int
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    init(from profile: UserProfile) {
        id = profile.id
        displayName = profile.displayName
        dayStartMinute = profile.dayStartMinute
        dayEndMinute = profile.dayEndMinute
        hasCompletedOnboarding = profile.hasCompletedOnboarding
        createdAt = profile.createdAt
        updatedAt = profile.updatedAt
    }

    func apply(_ profile: UserProfile) {
        displayName = profile.displayName
        dayStartMinute = profile.dayStartMinute
        dayEndMinute = profile.dayEndMinute
        hasCompletedOnboarding = profile.hasCompletedOnboarding
        updatedAt = profile.updatedAt
    }

    func toDomain() throws -> UserProfile {
        try UserProfile(
            restoringID: id,
            displayName: displayName,
            dayStartMinute: dayStartMinute,
            dayEndMinute: dayEndMinute,
            hasCompletedOnboarding: hasCompletedOnboarding,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
