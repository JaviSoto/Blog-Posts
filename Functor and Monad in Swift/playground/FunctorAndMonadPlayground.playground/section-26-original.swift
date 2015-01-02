extension Result {
  static func flatten<T>(result: Result<Result<T>>) -> Result<T> {
      switch result {
      case let .Value(innerResult):
          return innerResult.unbox
      case let .Error(error):
          return Result<T>.Error(error)
      }
  }
}
