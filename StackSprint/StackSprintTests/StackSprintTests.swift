import Testing
import Foundation
@testable import StackSprint

struct StackSprintTests {
    @Test func bundledCurriculumIsComplete() throws {
        let curriculum = try Curriculum.load()
        #expect(curriculum.lessons.count == 36)
        #expect(curriculum.questions.count == 50)
        #expect(Set(curriculum.lessons.map(\.id)).count == curriculum.lessons.count)
        #expect(curriculum.questions.allSatisfy { $0.answer >= 0 && $0.answer < $0.choices.count })
    }

    @Test func distributedBackendConfigContainsNoCredential() throws {
        let config = try #require(Bundle.main.url(forResource: "BackendConfig", withExtension: "json"))
        let text = try String(contentsOf: config, encoding: .utf8)
        #expect(text.contains("YOUR_"))
    }
}
