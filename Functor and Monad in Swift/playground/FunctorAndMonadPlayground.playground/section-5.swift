let number = Optional(815)

let transformedNumber = number.map { $0 * 2 }.map { $0 % 2 == 0 }
transformedNumber