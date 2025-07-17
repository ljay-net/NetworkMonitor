import SwiftUI
import UniformTypeIdentifiers

struct ExportedDocument: FileDocument {
    static var readableContentTypes: [UTType] { [UTType.commaSeparatedText, UTType.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static let commaSeparatedText = UTType(importedAs: "public.comma-separated-values-text")
}