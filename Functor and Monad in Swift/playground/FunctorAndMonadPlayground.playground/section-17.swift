let path = NSBundle.mainBundle().resourcePath!.stringByAppendingPathComponent("file.txt")
let data: Result<NSData> = dataWithContentsOfFile(path, NSUTF8StringEncoding)

let uppercaseContents: Result<String> = data.map { NSString(data: $0, encoding: NSUTF8StringEncoding)! }.map { $0.uppercaseString }
uppercaseContents
uppercaseContents.debugDescription