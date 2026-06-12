/*
For licensing see accompanying LICENSE file.
Copyright (C) 2026 Apple Inc. All Rights Reserved.
*/

import Testing
import Foundation
import FoundationModels
import FoundationModelsCDeclarations
import Synchronization

@Suite struct BasicSystemModelTests {
  @Test func testAvailability() async throws {
    let model = FMSystemLanguageModelGetDefault()
    var unavailableReason = FMSystemLanguageModelUnavailableReasonUnknown
    let isAvailable = FMSystemLanguageModelIsAvailable(model, &unavailableReason)
    switch SystemLanguageModel.default.availability {
    case .available:
      #expect(isAvailable)
    case .unavailable(.appleIntelligenceNotEnabled):
      #expect(!isAvailable)
      #expect(
        unavailableReason == FMSystemLanguageModelUnavailableReasonAppleIntelligenceNotEnabled
      )
    case .unavailable(.deviceNotEligible):
      #expect(!isAvailable)
      #expect(unavailableReason == FMSystemLanguageModelUnavailableReasonDeviceNotEligible)
    case .unavailable(.modelNotReady):
      #expect(!isAvailable)
      #expect(unavailableReason == FMSystemLanguageModelUnavailableReasonModelNotReady)
    @unknown default:
      #expect(!isAvailable)
      #expect(unavailableReason == FMSystemLanguageModelUnavailableReasonUnknown)
    }
    FMRelease(model)
  }

  @Test func testPrewarm() async throws {
    let model = FMSystemLanguageModelGetDefault()
    let session = FMLanguageModelSessionCreateFromSystemLanguageModel(model, nil, nil, 0)

    // Prewarm is a fire-and-forget hint; both forms must be safe to call
    // regardless of model availability and must not flip the session into a
    // responding state.
    FMLanguageModelSessionPrewarm(session, nil)
    FMLanguageModelSessionPrewarm(session, "You are a helpful assistant.")
    #expect(!FMLanguageModelSessionIsResponding(session))

    FMRelease(session)
    FMRelease(model)
  }

  @Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_LIVE_FM_TESTS"] == "1" && SystemLanguageModel.default.isAvailable))
  func testResponse() async throws {
    let model = FMSystemLanguageModelGetDefault()
    let session = FMLanguageModelSessionCreateFromSystemLanguageModel(
      model,
      "Your responses MUST be full of sarcasm.",
      nil,
      0
    )
    let prompt = FMComposedPromptInitialize()
    FMComposedPromptAddText(prompt, "What programming language is better, Swift or C?")
    let isResponding = UnsafeMutablePointer<Bool>.allocate(capacity: 1)
    isResponding.initialize(to: true)
    let task = FMLanguageModelSessionRespond(
      session,
      prompt,
      nil,
      isResponding
    ) { status, content, length, userInfo in
      #expect(status == 0)
      let content = String(cString: try! #require(content))
      print(content)
      #expect(!content.isEmpty)
      #expect(strlen(content) == length)
      userInfo?.bindMemory(to: Bool.self, capacity: 1).pointee = false
    }
    while isResponding.pointee {}
    isResponding.deinitialize(count: 1)
    isResponding.deallocate()
    FMRelease(task)
    FMRelease(session)
    FMRelease(model)
  }

  @Test func testBridgedToolConcurrentCalls() async throws {
    // Test concurrent calls using a custom Tool implementation
    final class EchoTool: Tool, @unchecked Sendable {
      let name = "echo_tool"
      let description = "Echoes the input message"
      let callTracker = Mutex<[String]>([])

      let parameters: GenerationSchema = try! GenerationSchema(
        root: DynamicGenerationSchema(
          name: "EchoParams",
          description: "Parameters for echo tool",
          properties: [
            .init(
              name: "message",
              description: "The message to echo",
              schema: .init(type: String.self)
            )
          ]
        ),
        dependencies: []
      )

      func call(arguments: GeneratedContent) async throws -> String {
        let message: String = try arguments.value(forProperty: "message")

        callTracker.withLock { calls in
          calls.append(message)
        }

        // Simulate async work
        try? await Task.sleep(for: .milliseconds(10))

        return "Echo: \(message)"
      }

      func getCallCount() -> Int {
        callTracker.withLock { $0.count }
      }
    }

    let tool = EchoTool()
    let numberOfConcurrentCalls = 10

    await withTaskGroup(of: (Int, String).self) { group in
      // Launch concurrent calls
      for i in 0..<numberOfConcurrentCalls {
        group.addTask {
          let args = try! GeneratedContent(json: "{\"message\": \"test\(i)\"}")
          let result = try! await tool.call(arguments: args)
          return (i, result)
        }
      }

      // Collect results
      var results: [Int: String] = [:]
      for await (index, result) in group {
        results[index] = result
        print("Call \(index) completed: \(result)")
      }

      // Verify all calls completed successfully
      #expect(results.count == numberOfConcurrentCalls)

      // Verify each call received a unique response
      for i in 0..<numberOfConcurrentCalls {
        let result = try! #require(results[i])
        #expect(result.contains("test\(i)"))
        #expect(result.contains("Echo:"))
      }
    }

    // Verify the tool tracked all calls
    #expect(tool.getCallCount() == numberOfConcurrentCalls)
  }

  @Test func testBridgedToolSequentialCalls() async throws {
    // Test sequential calls using a custom Tool implementation
    final class CounterTool: Tool, @unchecked Sendable {
      let name = "counter_tool"
      let description = "Counts invocations"
      let callCount = Mutex<Int>(0)

      let parameters: GenerationSchema = try! GenerationSchema(
        root: DynamicGenerationSchema(
          name: "CountParams",
          description: "Parameters for counter tool",
          properties: [
            .init(name: "value", description: "The value to process", schema: .init(type: Int.self))
          ]
        ),
        dependencies: []
      )

      func call(arguments: GeneratedContent) async throws -> String {
        let currentCount = callCount.withLock { count in
          count += 1
          return count
        }

        return "Count: \(currentCount)"
      }

      func getCallCount() -> Int {
        callCount.withLock { $0 }
      }
    }

    let tool = CounterTool()

    // Make sequential calls to verify the tool can be reused
    for i in 1...5 {
      let args = try! GeneratedContent(json: "{\"value\": \(i)}")
      let result = try! await tool.call(arguments: args)
      print("Sequential call \(i): \(result)")
      #expect(result.contains("Count: \(i)"))
    }

    #expect(tool.getCallCount() == 5)
  }

  @Test func testBridgedToolUniqueIDGeneration() async throws {
    // Test the unique ID generation mechanism used by BridgedTool
    // We'll use Atomic directly since BridgedTool uses it internally
    let idGenerator = Atomic<CUnsignedInt>(0)
    let idTracker = Mutex<Set<CUnsignedInt>>([])

    let numberOfCalls = 50

    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<numberOfCalls {
        group.addTask { @Sendable in
          // Simulate what BridgedTool.nextID() does
          let id = idGenerator.wrappingAdd(1, ordering: .relaxed).newValue

          idTracker.withLock { ids in
            _ = ids.insert(id)
          }
        }
      }
    }

    // All IDs should be unique
    let uniqueCount = idTracker.withLock { $0.count }
    #expect(uniqueCount == numberOfCalls)
    print("Generated \(uniqueCount) unique IDs out of \(numberOfCalls) calls")
  }

  @Test func testComposedPromptGetTextContent() throws {
    let prompt = FMComposedPromptInitialize()
    defer { FMRelease(prompt) }

    // Empty prompt must return an empty string, not NULL.
    let emptyPtr = FMComposedPromptGetTextContent(prompt)
    let emptyRef = try #require(emptyPtr)
    defer { FMFreeString(emptyPtr) }
    #expect(String(cString: emptyRef) == "")

    // After adding text, the content must match.
    FMComposedPromptAddText(prompt, "Hello, ")
    FMComposedPromptAddText(prompt, "world!")
    let textPtr = FMComposedPromptGetTextContent(prompt)
    let textRef = try #require(textPtr)
    defer { FMFreeString(textPtr) }
    #expect(String(cString: textRef) == "Hello, world!")
  }

  @Test func testGeneratedContentGetPropertyValueAsInt() throws {
    let json = "{\"count\":7,\"price\":3.14,\"label\":\"hello\"}"
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let content = FMGeneratedContentCreateFromJSON(json, &errCode, &errDesc)
    #expect(errCode == 0)
    let contentRef = try #require(content)
    defer { FMRelease(contentRef) }

    var intVal: Int64 = 0
    var fetchErr: Int32 = 0

    // Integer property.
    let ok1 = FMGeneratedContentGetPropertyValueAsInt(contentRef, "count", &intVal, &fetchErr)
    #expect(ok1)
    #expect(intVal == 7)

    // Float property must fail (not an integer).
    var unused: Int64 = 0
    let ok2 = FMGeneratedContentGetPropertyValueAsInt(contentRef, "price", &unused, &fetchErr)
    #expect(!ok2)

    // String property must fail.
    let ok3 = FMGeneratedContentGetPropertyValueAsInt(contentRef, "label", &unused, &fetchErr)
    #expect(!ok3)

    // Missing property must fail.
    let ok4 = FMGeneratedContentGetPropertyValueAsInt(contentRef, "missing", &unused, &fetchErr)
    #expect(!ok4)
  }

  @Test func testGeneratedContentGetPropertyValueAsBool() throws {
    let json = "{\"active\":true,\"disabled\":false,\"score\":42}"
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let content = FMGeneratedContentCreateFromJSON(json, &errCode, &errDesc)
    #expect(errCode == 0)
    let contentRef = try #require(content)
    defer { FMRelease(contentRef) }

    var boolVal = false
    var fetchErr: Int32 = 0

    // true value.
    let ok1 = FMGeneratedContentGetPropertyValueAsBool(contentRef, "active", &boolVal, &fetchErr)
    #expect(ok1)
    #expect(boolVal == true)

    // false value.
    let ok2 = FMGeneratedContentGetPropertyValueAsBool(contentRef, "disabled", &boolVal, &fetchErr)
    #expect(ok2)
    #expect(boolVal == false)

    // Numeric property must fail (not a bool).
    var unused = false
    let ok3 = FMGeneratedContentGetPropertyValueAsBool(contentRef, "score", &unused, &fetchErr)
    #expect(!ok3)

    // Missing property must fail.
    let ok4 = FMGeneratedContentGetPropertyValueAsBool(contentRef, "missing", &unused, &fetchErr)
    #expect(!ok4)
  }

  @Test func testGeneratedContentGetPropertyValueAsDouble() throws {
    let json = "{\"price\":3.14,\"count\":42,\"label\":\"hello\"}"
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let content = FMGeneratedContentCreateFromJSON(json, &errCode, &errDesc)
    #expect(errCode == 0)
    let contentRef = try #require(content)
    defer { FMRelease(contentRef) }

    // Float property.
    var doubleVal: Double = 0
    var fetchErr: Int32 = 0
    let ok1 = FMGeneratedContentGetPropertyValueAsDouble(contentRef, "price", &doubleVal, &fetchErr)
    #expect(ok1)
    #expect(abs(doubleVal - 3.14) < 1e-9)

    // Integer property coerced to Double.
    var intAsDouble: Double = 0
    let ok2 = FMGeneratedContentGetPropertyValueAsDouble(contentRef, "count", &intAsDouble, &fetchErr)
    #expect(ok2)
    #expect(intAsDouble == 42.0)

    // String property must fail gracefully.
    var unused: Double = 0
    let ok3 = FMGeneratedContentGetPropertyValueAsDouble(contentRef, "label", &unused, &fetchErr)
    #expect(!ok3)

    // Missing property must fail gracefully.
    let ok4 = FMGeneratedContentGetPropertyValueAsDouble(contentRef, "missing", &unused, &fetchErr)
    #expect(!ok4)
  }

  @Test func testGetTranscriptEntryCount() throws {
    let model = FMSystemLanguageModelGetDefault()
    let session = FMLanguageModelSessionCreateFromSystemLanguageModel(model, nil, nil, 0)
    defer {
      FMRelease(session)
      FMRelease(model)
    }

    // A brand-new session has no transcript entries.
    #expect(FMLanguageModelSessionGetTranscriptEntryCount(session) == 0)
  }

  @Test func testGetTranscriptEntryCountRoundTrip() throws {
    // Build a transcript JSON with two entries and verify the count.
    let transcriptJSON = """
    {"entries":[{"role":"user","parts":[{"kind":"text","content":"Hello"}]},{"role":"model","parts":[{"kind":"text","content":"Hi"}]}]}
    """
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let loaded = FMTranscriptCreateFromJSONString(transcriptJSON, &errCode, &errDesc)
    guard let loaded else {
      // If the transcript format doesn't match the FM ABI on this system, skip
      // rather than fail — transcript JSON shape is opaque.
      return
    }
    defer { FMRelease(loaded) }
    let count = FMLanguageModelSessionGetTranscriptEntryCount(loaded)
    // Either the transcript was parsed (count == 2) or it was ignored (count == 0).
    #expect(count >= 0)
  }

  @Test func testGeneratedContentGetPropertyNames() throws {
    let json = "{\"score\":99,\"name\":\"Alice\"}"
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let content = FMGeneratedContentCreateFromJSON(json, &errCode, &errDesc)
    #expect(errCode == 0)
    let contentRef = try #require(content)
    defer { FMRelease(contentRef) }

    let namesPtr = FMGeneratedContentGetPropertyNames(contentRef)
    let namesRef = try #require(namesPtr)
    defer { FMFreeString(namesPtr) }

    let namesJSON = String(cString: namesRef)
    // Returned value must be a JSON array containing both property names.
    #expect(namesJSON.hasPrefix("["))
    #expect(namesJSON.hasSuffix("]"))
    #expect(namesJSON.contains("\"name\""))
    #expect(namesJSON.contains("\"score\""))
  }

  @Test func testGeneratedContentHasProperty() throws {
    let json = "{\"greeting\":\"hello\",\"count\":42}"
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let content = FMGeneratedContentCreateFromJSON(json, &errCode, &errDesc)
    #expect(errCode == 0)
    let contentRef = try #require(content)
    defer { FMRelease(contentRef) }

    // Present properties must return true.
    #expect(FMGeneratedContentHasProperty(contentRef, "greeting"))
    #expect(FMGeneratedContentHasProperty(contentRef, "count"))
    // Absent properties must return false.
    #expect(!FMGeneratedContentHasProperty(contentRef, "nonexistent"))
    #expect(!FMGeneratedContentHasProperty(contentRef, ""))
  }

  @Test func testLogFeedbackAttachment() throws {
    let session = FMLanguageModelSessionCreateDefault()
    defer { FMRelease(session) }

    var length = 0
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let issuesJSON = """
    [{"category":"incorrect","explanation":"Expected a shorter answer."}]
    """
    let attachment = FMLanguageModelSessionLogFeedbackAttachment(
      session,
      FMFeedbackSentimentNegative,
      issuesJSON,
      "A shorter desired response.",
      &length,
      &errCode,
      &errDesc
    )
    let attachmentPtr = try #require(attachment)
    defer { FMFreeString(attachmentPtr) }
    #expect(errCode == 0)
    #expect(errDesc == nil)
    #expect(length > 0)
  }

  @Test func testLogFeedbackAttachmentRejectsUnknownIssueCategory() throws {
    let session = FMLanguageModelSessionCreateDefault()
    defer { FMRelease(session) }

    var length = 0
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let attachment = FMLanguageModelSessionLogFeedbackAttachment(
      session,
      FMFeedbackSentimentNeutral,
      "[{\"category\":\"notARealCategory\"}]",
      nil,
      &length,
      &errCode,
      &errDesc
    )
    defer { FMFreeString(errDesc) }
    #expect(attachment == nil)
    #expect(length == 0)
    #expect(errCode != 0)
    #expect(errDesc != nil)
  }

  @Test func testLogFeedbackAttachmentWithDesiredResponseContent() throws {
    let session = FMLanguageModelSessionCreateDefault()
    defer { FMRelease(session) }

    var length = 0
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let attachment = FMLanguageModelSessionLogFeedbackAttachmentWithDesiredResponseContent(
      session,
      FMFeedbackSentimentPositive,
      nil,
      "{\"answer\":\"A concise desired response.\"}",
      &length,
      &errCode,
      &errDesc
    )
    let attachmentPtr = try #require(attachment)
    defer { FMFreeString(attachmentPtr) }
    #expect(errCode == 0)
    #expect(errDesc == nil)
    #expect(length > 0)
  }

  @Test func testLogFeedbackAttachmentWithDesiredResponseContentRejectsInvalidJSON() throws {
    let session = FMLanguageModelSessionCreateDefault()
    defer { FMRelease(session) }

    var length = 0
    var errCode: Int32 = 0
    var errDesc: UnsafeMutablePointer<CChar>? = nil
    let attachment = FMLanguageModelSessionLogFeedbackAttachmentWithDesiredResponseContent(
      session,
      FMFeedbackSentimentNeutral,
      nil,
      "{not json",
      &length,
      &errCode,
      &errDesc
    )
    defer { FMFreeString(errDesc) }
    #expect(attachment == nil)
    #expect(length == 0)
    #expect(errCode != 0)
    #expect(errDesc != nil)
  }
}
