import Foundation

enum FileStoreError: LocalizedError {
    case readFailed(fileName: String, underlying: Error)
    case corruptFilePreserved(fileName: String, backupURL: URL?, underlying: Error)
    case writeFailed(fileName: String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .readFailed(let fileName, _):
            return "My Journey could not read \(fileName). Your existing file was left unchanged."
        case .corruptFilePreserved(let fileName, let backupURL, _):
            if let backupURL {
                return "My Journey recovered from a damaged \(fileName) file. The original was preserved as \(backupURL.lastPathComponent)."
            }
            return "My Journey found a damaged \(fileName) file and left it unchanged."
        case .writeFailed(let fileName, _):
            return "My Journey could not save \(fileName). No existing data was replaced."
        }
    }
}

struct FileStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager
    private let directoryURL: URL?

    init(fileManager: FileManager = .default, directoryURL: URL? = nil) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        self.encoder = encoder
        self.decoder = decoder
        self.fileManager = fileManager
        self.directoryURL = directoryURL
    }

    func load<T: Decodable>(_ type: T.Type, from fileName: String) throws -> T? {
        let url = fileURL(for: fileName)

        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            do {
                return try decoder.decode(type, from: data)
            } catch {
                let backupURL = preserveCorruptFile(at: url)
                throw FileStoreError.corruptFilePreserved(
                    fileName: fileName,
                    backupURL: backupURL,
                    underlying: error
                )
            }
        } catch {
            if error is FileStoreError {
                throw error
            }
            throw FileStoreError.readFailed(fileName: fileName, underlying: error)
        }
    }

    func save<T: Encodable>(_ value: T, to fileName: String) throws {
        let url = fileURL(for: fileName)

        do {
            try ensureDirectoryExists()
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            throw FileStoreError.writeFailed(fileName: fileName, underlying: error)
        }
    }

    private func preserveCorruptFile(at url: URL) -> URL? {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupURL = url.deletingPathExtension()
            .appendingPathExtension("corrupt-\(timestamp).json")

        do {
            try fileManager.moveItem(at: url, to: backupURL)
            return backupURL
        } catch {
            return nil
        }
    }

    private func fileURL(for fileName: String) -> URL {
        appSupportDirectory.appendingPathComponent(fileName, isDirectory: false)
    }

    private var appSupportDirectory: URL {
        if let directoryURL {
            return directoryURL
        }

        let baseDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return baseDirectory.appendingPathComponent("MyJourney", isDirectory: true)
    }

    private func ensureDirectoryExists() throws {
        try fileManager.createDirectory(
            at: appSupportDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
}
