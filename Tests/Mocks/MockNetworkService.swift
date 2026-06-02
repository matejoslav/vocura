import Foundation
@testable import Vocura

/// Mock Network Service for testing. Returns predefined responses without making real network calls.
class MockNetworkService: NetworkServiceProtocol {
    /// The data to return in the completion handler
    var mockData: Data?
    
    /// The response to return in the completion handler
    var mockResponse: URLResponse?
    
    /// The error to return in the completion handler
    var mockError: Error?
    
    /// Tracks if sendRequest was called
    var sendRequestCallCount = 0
    var lastRequest: URLRequest?
    
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        sendRequestCallCount += 1
        lastRequest = request
        completion(mockData, mockResponse, mockError)
    }
    
    /// Reset all state for clean test setup
    func reset() {
        mockData = nil
        mockResponse = nil
        mockError = nil
        sendRequestCallCount = 0
        lastRequest = nil
    }
    
    // MARK: - Helper methods for common test scenarios
    
    /// Configure mock to return a successful Deepgram response with given transcript
    func setSuccessResponse(transcript: String) {
        let response = DeepgramResponse(
            results: DeepgramResponse.Results(
                channels: [
                    DeepgramResponse.Results.Channel(
                        alternatives: [
                            DeepgramResponse.Results.Channel.Alternative(transcript: transcript)
                        ]
                    )
                ]
            )
        )
        mockData = try? JSONEncoder().encode(response)
        mockError = nil
    }
    
    /// Configure mock to return a network error
    func setNetworkError(_ error: Error) {
        mockData = nil
        mockError = error
    }
    
    /// Configure mock to return empty data
    func setEmptyResponse() {
        mockData = nil
        mockError = nil
    }
}
