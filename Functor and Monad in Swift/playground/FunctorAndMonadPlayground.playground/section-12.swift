import Foundation

class Box<T> {
    let unbox: T

    init(_ value: T) {
        self.unbox = value
    }
}

enum Result<T> {
    case Value(Box<T>)
    case Error(NSError)
}

extension Result: DebugPrintable {
  var debugDescription: String {
    switch self {
      case let .Value(value):
      return "Value: \(toDebugString(value.unbox))"
      case let .Error(error):
      return "Error: \(toDebugString(error))"
    }
  }
}
