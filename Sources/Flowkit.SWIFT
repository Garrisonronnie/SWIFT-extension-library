import Foundation
import Combine

// MARK: - NETWORK MANAGER
class NetworkManager {
    static let shared = NetworkManager()
    private var cache = [URL: Data]()
    private var offlineQueue = [(URL, Int, (Data?, Error?) -> Void)]()
    private var isOnline = true
    
    func setOnline(_ status: Bool) {
        isOnline = status
        if isOnline {
            processQueue()
        }
    }
    
    private func processQueue() {
        for (url, retries, completion) in offlineQueue {
            request(url: url, retries: retries, completion: completion)
        }
        offlineQueue.removeAll()
    }
    
    func request(url: URL, retries: Int = 3, completion: @escaping (Data?, Error?) -> Void) {
        if let cachedData = cache[url] {
            completion(cachedData, nil)
            return
        }
        
        guard isOnline else {
            offlineQueue.append((url, retries, completion))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error, retries > 0 {
                let delay = pow(2.0, Double(4 - retries))
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.request(url: url, retries: retries - 1, completion: completion)
                }
                return
            }
            
            if let data = data {
                self.cache[url] = data
            }
            completion(data, error)
        }
        task.resume()
    }
}

// MARK: - JSON PARSER
struct JSONParser {
    static func parse<T: Decodable>(_ data: Data, type: T.Type) -> Result<T, Error> {
        let decoder = JSONDecoder()
        do {
            let model = try decoder.decode(T.self, from: data)
            return .success(model)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - LOCAL DATABASE
class LocalDatabase<T: Codable> {
    private var storage = [T]()
    var publisher = PassthroughSubject<[T], Never>()
    
    func add(_ item: T) {
        storage.append(item)
        publisher.send(storage)
    }
    
    func remove(_ item: T) where T: Equatable {
        storage.removeAll { $0 == item }
        publisher.send(storage)
    }
    
    func all() -> [T] {
        return storage
    }
    
    func clear() {
        storage.removeAll()
        publisher.send(storage)
    }
}

// MARK: - API CLIENT
enum APIEndpoint {
    case users
    case posts
    
    var url: URL {
        switch self {
        case .users: return URL(string: "https://jsonplaceholder.typicode.com/users")!
        case .posts: return URL(string: "https://jsonplaceholder.typicode.com/posts")!
        }
    }
}

class APIClient {
    static let shared = APIClient()
    private var cache = [URL: Data]()
    
    func fetch(_ endpoint: APIEndpoint, retries: Int = 2, completion: @escaping (Data?, Error?) -> Void) {
        if let cachedData = cache[endpoint.url] {
            completion(cachedData, nil)
            return
        }
        
        NetworkManager.shared.request(url: endpoint.url, retries: retries) { data, error in
            if let data = data {
                self.cache[endpoint.url] = data
            }
            completion(data, error)
        }
    }
}

// MARK: - USAGE EXAMPLES
struct Note: Codable, Equatable {
    let title: String
}

let notesDB = LocalDatabase<Note>()
let cancellable = notesDB.publisher.sink { notes in
    print("Database updated:", notes)
}

notesDB.add(Note(title: "First note"))
notesDB.add(Note(title: "Second note"))

APIClient.shared.fetch(.users) { data, error in
    if let data = data {
        let result = JSONParser.parse(data, type: [[String: Any]].self)
        switch result {
        case .success(let users):
            print("Users:", users)
        case .failure(let error):
            print("JSON Error:", error)
        }
    } else if let error = error {
        print("Network Error:", error)
    }
}
