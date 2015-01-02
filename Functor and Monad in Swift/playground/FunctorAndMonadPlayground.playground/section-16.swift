extension Result {
  func map<U>(f: T -> U) -> Result<U> {
    switch self {
      case let .Value(value):
      return Result<U>.Value(Box(f(value.unbox)))
      case let .Error(error):
      return Result<U>.Error(error)
    }
  }
}
