extension Result {
  func flatMap<U>(f: T -> Result<U>) -> Result<U> {
      return Result.flatten(map(f))
  }
}