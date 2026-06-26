import XCTest
import Foundation
@testable import Vocura

/// Tests for WindowManager's recording orchestration with injected dependencies.
final class WindowManagerTests: XCTestCase {

    var mockRecorder: MockAudioRecorder!
    var mockSTT: MockSTTService!
    var mockInserter: MockTextInserter!
    var windowManager: WindowManager!

    override func setUp() {
        super.setUp()
        mockRecorder = MockAudioRecorder()
        mockSTT = MockSTTService()
        mockInserter = MockTextInserter()
        windowManager = WindowManager(
            recorder: mockRecorder,
            sttService: mockSTT,
            textInserter: mockInserter
        )
    }

    override func tearDown() {
        mockRecorder = nil
        mockSTT = nil
        mockInserter = nil
        windowManager = nil
        super.tearDown()
    }

    func testStartRecordingStartsRecorder() {
        windowManager.startRecording()

        XCTAssertEqual(mockRecorder.startCallCount, 1)
        XCTAssertTrue(windowManager.isRecording)
    }

    func testStopRecordingStopsRecorderAndTranscribes() {
        mockRecorder.audioFileURL = URL(fileURLWithPath: "/tmp/recording.m4a")

        windowManager.stopRecording()

        XCTAssertEqual(mockRecorder.stopCallCount, 1)
        XCTAssertEqual(mockSTT.transcribeCallCount, 1)
        XCTAssertEqual(mockSTT.lastAudioURL?.path, "/tmp/recording.m4a")
        XCTAssertFalse(windowManager.isRecording)
    }

    func testSuccessfulTranscriptionInsertsText() {
        mockRecorder.audioFileURL = URL(fileURLWithPath: "/tmp/recording.m4a")
        mockSTT.result = .success("Hello, world!")

        let expectation = expectation(description: "Text inserted")
        mockInserter.onInsert = { _ in expectation.fulfill() }

        windowManager.stopRecording()

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(mockInserter.lastInsertedText, "Hello, world!")
    }

    func testFailedTranscriptionDoesNotInsertText() {
        mockRecorder.audioFileURL = URL(fileURLWithPath: "/tmp/recording.m4a")
        mockSTT.result = .failure(NSError(domain: "Test", code: 1))

        let expectation = expectation(description: "Error surfaced")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { expectation.fulfill() }

        windowManager.stopRecording()

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(mockInserter.insertCallCount, 0)
        XCTAssertNotNil(windowManager.statusMessage)
    }
}
