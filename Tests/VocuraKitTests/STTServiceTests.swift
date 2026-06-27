import XCTest
import Foundation
@testable import VocuraKit

/// Tests for STTService with mocked dependencies
final class STTServiceTests: XCTestCase {
    
    var mockKeychain: MockKeychain!
    var mockNetwork: MockNetworkService!
    var sttService: STTService!
    var tempAudioURL: URL!
    
    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychain()
        mockNetwork = MockNetworkService()
        sttService = STTService(keychainService: mockKeychain, networkService: mockNetwork)
        
        // Create a temporary audio file for testing
        tempAudioURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_audio.m4a")
        FileManager.default.createFile(atPath: tempAudioURL.path, contents: Data("fake audio data".utf8), attributes: nil)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempAudioURL)
        mockKeychain = nil
        mockNetwork = nil
        sttService = nil
        super.tearDown()
    }
    
    // MARK: - API Key Validation Tests
    
    func testTranscribeFailsWhenNoAPIKey() {
        // Given: No API key configured
        mockKeychain.mockValue = nil
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .failure(let error) = capturedResult else {
            XCTFail("Expected failure when no API key")
            return
        }
        XCTAssertEqual((error as NSError).code, -3)
        XCTAssertEqual(mockNetwork.sendRequestCallCount, 0, "No network call should be made without API key")
    }
    
    func testTranscribeFailsWhenAPIKeyEmpty() {
        // Given: Empty API key
        mockKeychain.mockValue = ""
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .failure(let error) = capturedResult else {
            XCTFail("Expected failure when API key is empty")
            return
        }
        XCTAssertEqual((error as NSError).code, -3)
    }
    
    // MARK: - Success Response Tests
    
    func testTranscribeReturnsTranscriptOnSuccess() {
        // Given
        mockKeychain.mockValue = "test-api-key"
        mockNetwork.setSuccessResponse(transcript: "Hello, world!")
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .success(let transcript) = capturedResult else {
            XCTFail("Expected success")
            return
        }
        XCTAssertEqual(transcript, "Hello, world!")
    }
    
    func testTranscribeSendsCorrectAuthorizationHeader() {
        // Given
        mockKeychain.mockValue = "my-secret-key"
        mockNetwork.setSuccessResponse(transcript: "Test")
        
        // When
        let expectation = expectation(description: "Completion called")
        
        sttService.transcribe(audioURL: tempAudioURL) { _ in
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        XCTAssertEqual(mockNetwork.sendRequestCallCount, 1)
        XCTAssertEqual(mockNetwork.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Token my-secret-key")
        XCTAssertEqual(mockNetwork.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "audio/m4a")
    }
    
    // MARK: - Error Handling Tests
    
    func testTranscribeHandlesNetworkError() {
        // Given
        mockKeychain.mockValue = "test-api-key"
        let networkError = NSError(domain: "Network", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet"])
        mockNetwork.setNetworkError(networkError)
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .failure(let error) = capturedResult else {
            XCTFail("Expected failure on network error")
            return
        }
        XCTAssertEqual((error as NSError).code, -1009)
    }
    
    func testTranscribeHandlesNoDataResponse() {
        // Given
        mockKeychain.mockValue = "test-api-key"
        mockNetwork.setEmptyResponse()
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .failure(let error) = capturedResult else {
            XCTFail("Expected failure when no data received")
            return
        }
        XCTAssertEqual((error as NSError).code, -1)
    }
    
    func testTranscribeHandlesMalformedJSON() {
        // Given
        mockKeychain.mockValue = "test-api-key"
        mockNetwork.mockData = Data("not valid json".utf8)
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .failure = capturedResult else {
            XCTFail("Expected failure on malformed JSON")
            return
        }
    }
    
    func testTranscribeHandlesEmptyTranscript() {
        // Given: Valid JSON response but no transcript
        mockKeychain.mockValue = "test-api-key"
        let emptyResponse = DeepgramResponse(results: DeepgramResponse.Results(channels: []))
        mockNetwork.mockData = try? JSONEncoder().encode(emptyResponse)
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: tempAudioURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then
        guard case .failure(let error) = capturedResult else {
            XCTFail("Expected failure when no transcript found")
            return
        }
        XCTAssertEqual((error as NSError).code, -2)
    }
    
    // MARK: - Audio File Tests
    
    func testTranscribeFailsForMissingAudioFile() {
        // Given
        mockKeychain.mockValue = "test-api-key"
        let nonexistentURL = URL(fileURLWithPath: "/nonexistent/audio.m4a")
        
        // When
        let expectation = expectation(description: "Completion called")
        var capturedResult: Result<String, Error>?
        
        sttService.transcribe(audioURL: nonexistentURL) { result in
            capturedResult = result
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        // Then: Should fail with file reading error (not network error)
        guard case .failure = capturedResult else {
            XCTFail("Expected failure for missing audio file")
            return
        }
        XCTAssertEqual(mockNetwork.sendRequestCallCount, 0, "Network should not be called for missing file")
    }
}
