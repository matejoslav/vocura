import Foundation

public class STTService: SpeechToTextService {
    private let keychainService: KeychainServiceProtocol
    private let networkService: NetworkServiceProtocol
    
    public init(
        keychainService: KeychainServiceProtocol = KeychainHelper.shared,
        networkService: NetworkServiceProtocol = URLSessionNetworkService.shared
    ) {
        self.keychainService = keychainService
        self.networkService = networkService
    }
    
    public func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = keychainService.load(), !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "STTService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Deepgram API key not set. Please open Settings."])))
            return
        }
        
        let url = URL(string: "https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/m4a", forHTTPHeaderField: "Content-Type")
        
        do {
            let data = try Data(contentsOf: audioURL)
            request.httpBody = data
        } catch {
            completion(.failure(error))
            return
        }
        
        networkService.sendRequest(request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "STTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(DeepgramResponse.self, from: data)
                if let transcript = result.results?.channels?.first?.alternatives?.first?.transcript {
                    completion(.success(transcript))
                } else {
                    completion(.failure(NSError(domain: "STTService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No transcript found"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public struct DeepgramResponse: Codable {
    public struct Results: Codable {
        public struct Channel: Codable {
            public struct Alternative: Codable {
                public let transcript: String?
            }
            public let alternatives: [Alternative]?
        }
        public let channels: [Channel]?
    }
    public let results: Results?
    
    public init(results: Results?) {
        self.results = results
    }
}

