import Foundation
import XCTest
@testable import MyJourney

final class FileStoreTests: XCTestCase {
    private struct Fixture: Codable, Equatable {
        let name: String
        let count: Int
    }

    func testRoundTripsAValueAtomically() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileStore(directoryURL: directory)
        let fixture = Fixture(name: "Journey", count: 5)

        try store.save(fixture, to: "fixture.json")
        let loaded = try store.load(Fixture.self, from: "fixture.json")

        XCTAssertEqual(loaded, fixture)
    }

    func testPreservesCorruptFileInsteadOfSilentlyOverwritingIt() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let originalURL = directory.appendingPathComponent("fixture.json")
        try Data("not-json".utf8).write(to: originalURL)
        let store = FileStore(directoryURL: directory)

        XCTAssertThrowsError(try store.load(Fixture.self, from: "fixture.json")) { error in
            guard case FileStoreError.corruptFilePreserved(_, let backupURL, _) = error else {
                return XCTFail("Expected a preserved corrupt-file error, got \(error)")
            }
            XCTAssertNotNil(backupURL)
            XCTAssertEqual(try? Data(contentsOf: backupURL!), Data("not-json".utf8))
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: originalURL.path))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MyJourneyTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
