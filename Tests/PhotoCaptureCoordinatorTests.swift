import XCTest
@testable import Sprout

/// Unit tests for the sequential photo coordinator (T206), exercised through a stub
/// camera + in-memory repository so no hardware is needed.
@MainActor
final class PhotoCaptureCoordinatorTests: XCTestCase {
    private var repo: PlantRepository!
    private var plants: [Plant] = []

    override func setUpWithError() throws {
        try super.setUpWithError()
        repo = try PlantStore.inMemory()
        plants = [
            Plant(nickname: "Violet", species: "Pothos"),
            Plant(nickname: "Charlotte", species: "Snake Plant"),
            Plant(nickname: "Ava", species: "Boston Fern"),
        ]
        for plant in plants { try repo.add(plant) }
    }

    override func tearDownWithError() throws {
        repo = nil
        plants = []
        try super.tearDownWithError()
    }

    private func makeCoordinator(
        camera: PhotoCapturing? = nil
    ) -> PhotoCaptureCoordinator {
        PhotoCaptureCoordinator(
            targets: plants.map(PhotoCaptureCoordinator.Target.init(plant:)),
            repository: repo,
            camera: camera ?? StubPhotoCapturing()
        )
    }

    private func photoData(of index: Int) throws -> Data? {
        try XCTUnwrap(repo.plant(id: plants[index].id)).photoData
    }

    func testStartsOnFirstTarget() {
        let c = makeCoordinator()
        XCTAssertEqual(c.index, 0)
        XCTAssertEqual(c.current?.nickname, "Violet")
        XCTAssertFalse(c.isFinished)
    }

    func testBannerNamesCurrentPlant() {
        let c = makeCoordinator()
        XCTAssertEqual(c.bannerText, "Now photographing Violet — Pothos")
        XCTAssertEqual(c.progressText, "1 of 3")
    }

    func testCaptureSavesPhotoAndAdvances() async throws {
        let c = makeCoordinator()
        await c.captureCurrent()
        XCTAssertNotNil(try photoData(of: 0), "current plant got a photo")
        XCTAssertEqual(c.index, 1)
        XCTAssertEqual(c.current?.nickname, "Charlotte")
    }

    func testSkipAdvancesWithoutSaving() throws {
        let c = makeCoordinator()
        c.skip()
        XCTAssertNil(try photoData(of: 0), "skip must not save a photo")
        XCTAssertEqual(c.index, 1)
    }

    func testWalkingAllTargetsFinishes() async throws {
        let c = makeCoordinator()
        await c.captureCurrent() // Violet
        c.skip()                 // Charlotte
        await c.captureCurrent() // Ava
        XCTAssertTrue(c.isFinished)
        XCTAssertNil(c.current)
        XCTAssertNotNil(try photoData(of: 0))
        XCTAssertNil(try photoData(of: 1))
        XCTAssertNotNil(try photoData(of: 2))
    }

    func testFailedCaptureStaysAndDoesNotSave() async throws {
        let c = makeCoordinator(camera: StubPhotoCapturing(returnsImage: false))
        await c.captureCurrent()
        XCTAssertEqual(c.index, 0, "a failed capture stays on the current plant")
        XCTAssertNil(try photoData(of: 0))
        XCTAssertFalse(c.isFinished)
    }

    func testCameraAvailabilityReflectsTheSource() {
        XCTAssertFalse(makeCoordinator(camera: StubPhotoCapturing(isAvailable: false)).cameraAvailable)
        XCTAssertTrue(makeCoordinator(camera: StubPhotoCapturing(isAvailable: true)).cameraAvailable)
    }

    func testEmptyTargetsFinishImmediately() {
        let c = PhotoCaptureCoordinator(targets: [], repository: repo, camera: StubPhotoCapturing())
        XCTAssertTrue(c.isFinished)
        XCTAssertNil(c.current)
    }
}
