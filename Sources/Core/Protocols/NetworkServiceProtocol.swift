import Foundation

/// Protocol abstraction for network requests, enabling dependency injection and testing.
public protocol NetworkServiceProtocol {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}

/// Default implementation using URLSession.
public class URLSessionNetworkService: NetworkServiceProtocol {
    public static let shared = URLSessionNetworkService()
    
    private init() {}
    
    public func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            completion(data, response, error)
        }.resume()
    }
}
