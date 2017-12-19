//: Playground - noun: a place where people can play
import PlaygroundSupport
import UIKit

struct StarwarsCharacter: Codable {
  let name: String
}

enum APIResult<T> {
  case failure(Error), success(T)
}

func getCharacters(completion: @escaping (APIResult<[StarwarsCharacter]>) -> ()) {
  var characters: [StarwarsCharacter] = []
  var mostRecentError: Error?
  let group = DispatchGroup()
  let writeQueue = DispatchQueue(label: "StarwarsCharacter")
  let urls = (1...9).flatMap { URL(string: "https://swapi.co/api/people/\($0)") }
  urls.forEach { url in
    group.enter()
    URLSession.shared.dataTask(with: url) { data, response, error in
      defer {
        group.leave()
      }
      guard error == nil,
        let data = data,
        let character = try? JSONDecoder().decode(StarwarsCharacter.self, from: data) else {
          writeQueue.async {
            mostRecentError = error ?? NSError(domain: "Unknown API Error", code: 0, userInfo: nil)
          }
          return
      }
      writeQueue.async {
        characters.append(character)
      }
      }.resume()
  }
  group.notify(queue: .main) {
    switch mostRecentError {
    case .some(let error):
      completion(.failure(error))
    case .none:
      completion(.success(characters))
    }
  }
}

PlaygroundPage.current.needsIndefiniteExecution = true
getCharacters() { result in
  switch result {
  case .failure(let error):
    print(error.localizedDescription)
  case .success(let characters):
    characters.forEach {print($0.name)}
  }
}
