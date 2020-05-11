# GMSNetworkLayer
[![Build Status](https://travis-ci.com/GabrielSilveiraa/GMSNetworkLayer.svg?branch=master)](https://travis-ci.com/GabrielSilveiraa/GMSNetworkLayer) [![codecov](https://codecov.io/gh/GabrielSilveiraa/GMSNetworkLayer/branch/master/graph/badge.svg)](https://codecov.io/gh/GabrielSilveiraa/GMSNetworkLayer)


## Requirements

- iOS 12.2+
- Xcode 11+
- Swift 5.0+

## Instalation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate GMSNetworkLayer into your Xcode project using CocoaPods, specify it in your `Podfile`:

```
pod 'GMSNetworkLayer', '~> 1.1'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate GMSNetworkLayer into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "GabrielSilveiraa/GMSNetworkLayer" ~> 1.1
```

## Usage

Create an Enum wich agrees with `EndPointType` Protocol. 
Example:

```
enum BookApi {
    case case booksList(_ index: Int)
}

extension BookApi: EndPointType {
    var baseURL: URL {
         guard let url = URL(string: "https://www.googleapis.com") else {
            fatalError("baseURL could not be configured.")
        }
        return url
    }
    
    var path: String {
        switch self {
        case .booksList:
            return "/books/v1/volumes"
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .booksList:
            return .get
        }
    }
    
    var encoding: ParameterEncoding? {
        switch self {
        case .booksList:
            return .urlEncoding
        }
    }
    
    var parameters: [String : Any] {
        switch self {
        case .booksList(let index):
            return ["q" : "ios",
                    "maxResults" : 20,
                    "startIndex" : index]
        }
    }
}
```
Then create your service class as follows:

```
class BooksListService {
    let networkManager: NetworkManager
    
    init(session: URLSession = .shared) {
        networkManager = NetworkManager(session: session)
    }
}

extension BooksListService: BooksListServiceProtocol {
    func getBooksList(index: Int, completion: @escaping (Result<BookVolumes, Error>) -> Void) {
        let endPoint = BookApi.booksList(index)
        networkManager.request(endPoint, completion: completion)
    }
}
```

The Result Object has to agree with Decodable protocol as the example below:

```
struct BookVolumes: Decodable {
    let items: [BookVolume]?
}

struct BookVolume: Decodable {
    let id: String
}
```
