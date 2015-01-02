let nilNumber: Int? = .None

let transformedNilNumber = nilNumber.map { $0 * 2 }.map { $0 % 2 == 0 }
transformedNilNumber
