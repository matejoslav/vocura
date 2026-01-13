import Foundation

class STTService {
    
    func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = KeychainHelper.shared.load(), !apiKey.isEmpty else {
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
        
        URLSession.shared.dataTask(with: request) { data, response, error in
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
        }.resume()
    }
}

struct DeepgramResponse: Codable {
    struct Results: Codable {
        struct Channel: Codable {
            struct Alternative: Codable {
                let transcript: String?
            }
            let alternatives: [Alternative]?
        }
        let channels: [Channel]?
    }
    let results: Results?
}
