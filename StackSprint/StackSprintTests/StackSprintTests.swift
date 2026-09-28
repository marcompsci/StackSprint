//
//  StackSprintTests.swift
//  StackSprintTests
//
//  Created by Omari Bell on 9/22/26.
//

import Testing
import Foundation

struct StackSprintTests {

    // Runs before each @Test — used here to debug the Anthropic REST API connection
    init() async throws {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? "", forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-opus-4-8",
            "max_tokens": 16,
            "messages": [["role": "user", "content": "Hello"]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[Anthropic Debug] Status: \(statusCode)")
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("[Anthropic Debug] Response: \(json)")
        }
    }

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
    }

}
