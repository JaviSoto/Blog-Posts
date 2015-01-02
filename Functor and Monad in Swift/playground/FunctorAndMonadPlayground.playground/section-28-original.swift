let JSErrorCodeInvalidStringData = 123

let stringResult = Result<String>.flatten(data.map { (data: NSData) -> (Result<String>) in
  if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
    return Result.Value(Box(string))
  }
  else {
    return Result<String>.Error(NSError(domain: "com.javisoto.es.error_domain", code: JSErrorCodeInvalidStringData, userInfo: nil))
  }
})
stringResult.debugDescription
