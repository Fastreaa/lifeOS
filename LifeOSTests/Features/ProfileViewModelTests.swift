import XCTest
@testable import LifeOS

@MainActor
final class ProfileViewModelTests: XCTestCase {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func makeSUT(
        repository: (any ProfileRepository)? = nil,
        suppressesOnboarding: Bool = false
    ) throws -> (ProfileViewModel, any ProfileRepository) {
        let repository = try repository ?? AppDependencies(inMemory: true).profileRepository
        let fixedNow = start
        let viewModel = ProfileViewModel(
            repository: repository,
            suppressesOnboarding: suppressesOnboarding,
            calendar: calendar
        ) { fixedNow }
        return (viewModel, repository)
    }

    private func draft(name: String, from startHour: Int, to endHour: Int) throws -> ProfileDraft {
        var draft = ProfileDraft(profile: .makeDefault(now: start), calendar: calendar)
        draft.name = name
        draft.dayStart = try XCTUnwrap(calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: start))
        draft.dayEnd = try XCTUnwrap(calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: start))
        return draft
    }

    func test_firstLaunch_showsOnboarding() throws {
        let (viewModel, _) = try makeSUT()

        viewModel.load()

        XCTAssertTrue(viewModel.isShowingOnboarding)
    }

    func test_suppressedOnboarding_isNotShown() throws {
        let (viewModel, _) = try makeSUT(suppressesOnboarding: true)

        viewModel.load()

        XCTAssertFalse(viewModel.isShowingOnboarding)
    }

    func test_completeOnboarding_savesAndHides() throws {
        let (viewModel, repository) = try makeSUT()
        viewModel.load()

        try viewModel.completeOnboarding(with: try draft(name: "Ana", from: 6, to: 22))

        XCTAssertFalse(viewModel.isShowingOnboarding)
        XCTAssertEqual(viewModel.displayName, "Ana")
        XCTAssertEqual(viewModel.profile.dayWindow, 360...1320)
        XCTAssertEqual(try repository.loadProfile()?.hasCompletedOnboarding, true)
    }

    func test_skipOnboarding_isRememberedOnNextLaunch() throws {
        let (viewModel, repository) = try makeSUT()
        viewModel.load()

        viewModel.skipOnboarding()

        let (relaunched, _) = try makeSUT(repository: repository)
        relaunched.load()
        XCTAssertFalse(relaunched.isShowingOnboarding)
        XCTAssertEqual(relaunched.profile.dayWindow, DayPlan.defaultWindow)
    }

    func test_bedtimeAtMidnight_isEndOfDay() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()

        try viewModel.save(try draft(name: "", from: 8, to: 0))

        XCTAssertEqual(viewModel.profile.dayEndMinute, 1440)
        XCTAssertNil(viewModel.displayName)
    }

    func test_save_withInvalidHours_throwsAndKeepsProfile() throws {
        let (viewModel, _) = try makeSUT()
        viewModel.load()
        let original = viewModel.profile

        XCTAssertThrowsError(try viewModel.save(try draft(name: "Ana", from: 22, to: 8))) {
            XCTAssertEqual($0 as? ProfileValidationError, .invalidDayWindow)
        }
        XCTAssertEqual(viewModel.profile, original)
    }
}
