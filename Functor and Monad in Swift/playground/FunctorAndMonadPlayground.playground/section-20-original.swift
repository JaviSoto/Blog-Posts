var stringContents: String?

switch data {
  case let .Value(value):
    stringContents = NSString(data: value.unbox, encoding: NSUTF8StringEncoding)
  case let .Error(error):
    break
}

let uppercaseContents2: String? = stringContents?.uppercaseString
uppercaseContents2
