# SwiftCoreKit

**SwiftCoreKit** is a **modern, fully legal Swift module** for **networking, JSON handling, and reactive local storage**. It provides functionality missing from popular libraries like Alamofire, SwiftyJSON, Realm, and Moya, while being fully original and safe to use.  

---

## Features

### Networking
- HTTP requests with **automatic retry/backoff**  
- Response **caching**  
- **Offline queueing** for requests when offline  

### JSON Handling
- **Type-safe JSON parsing** using `Decodable`  
- Automatic **schema validation** against models  

### Local Database
- Reactive updates using **Combine**  
- Full control over stored objects  
- Optional **cloud sync integration**  

### Declarative API Client
- Simple and clean **endpoint management**  
- Integrates with `NetworkManager` for retries, caching, and offline support  

---

## Installation

1. Copy `SwiftCoreKit.swift` into your project.  
2. Ensure your project targets **iOS 13+** for Combine support.  

---

## Usage

```swift
import SwiftCoreKit

// MARK: - Reactive Local Database Example
struct Note: Codable, Equatable {
    let title: String
}

let db = LocalDatabase<Note>()
let cancellable = db.publisher.sink { notes in
    print("Database updated:", notes)
}
db.add(Note(title: "First note"))

// MARK: - API Fetch Example
APIClient.shared.fetch(.users) { data, error in
    if let data = data {
        let result = JSONParser.parse(data, type: [[String: Any]].self)
        switch result {
        case .success(let users):
            print(users)
        case .failure(let error):
            print(error)
        }
    } else if let error = error {
        print(error)
    }
}