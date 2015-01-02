func dataWithContentsOfFile(file: String, encoding: NSStringEncoding) -> Result<NSData> {
  var error: NSError?

  if let data = NSData(contentsOfFile: file, options: .allZeros, error: &error) {
    return .Value(Box(data))
  }
  else {
    return .Error(error!)
  }
}