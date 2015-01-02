# Functor and Monad in Swift

I have been trying to teach myself Functional Programming since late 2013. Many of the concepts are very daunting because of their somewhat academic nature.

Since I'm obviously not an expert, I intend this to be a very practical post. You will find many posts trying to explain what a Monad is, [some of them trying a bit too hard to come up with similes](http://blog.plover.com/prog/burritos.html), but hopefully the sample code here will illustrate some of the concepts better.

It wasn't until recently that I finally could say that I *got* what Monad means. Let's explore why this concept even exists, and how it can help you when writing Swift code.

## Map
One of the first things that we got to see at the 2014 WWDC with the introduction of Swift was that we could use the `map` function with the collection types. Let's focus on Swift's `Array`.

```swift
let numbers = [1, 2, 3]

let doubledNumbers = numbers.map { $0 * 2 }
// doubledNumbers: 2, 4, 6
```

The benefit of this pattern is that we can very clearly express the transformation that we're trying to apply on the list of elements (in this case, doubling their value). Compare this with the imperative approach:

```swift
var doubledImperative: [Int] = []
for number in numbers {
  doubledImperative.append(number * 2)
}
// doubledImperative: 2, 4, 6
```

It's not about solving it in a one-liner vs 3 lines, but with the former concise implementation, there's a significantly higher signal-to-noise ratio. `map` allows us to express *what* we want to achieve, rather than *how* this is implemented. This eases our ability to reason about code when we read it.

But `map` doesn't only make sense on `Array`. `map` is a higher-order function that can be implemented on just any container type. That is, any type that, one way or another, wraps one or multiple values inside.

Let's look at another example: `Optional`. `Optional` is a container type that wraps a value, or the absence of it.

```swift
let number = Optional(815)

let transformedNumber = number.map { $0 * 2 }.map { $0 % 2 == 0 }
// transformedNumber: Optional.Some(true)
```

The benefit of `map` in `Optional` is that it will handle nil values for us. If we're trying to operate on a value that *may* be `nil`, we can use `Optional.map` to apply those transformations, and end up with `nil` if the original value was `nil`, but without having to resort to nested `if let` to unwrap the optional.

```swift
let nilNumber: Int? = .None

let transformedNilNumber = nilNumber.map { $0 * 2 }.map { $0 % 2 == 0 }
// transformedNilNumber: None
```

From this we can extrapolate that **`map`, when implemented on different container types, can have slightly different behaviors**, depending on the semantics of that type. For example, it only makes sense to transform the value inside an `Optional` when there's actually a value inside.

This is the general **signature of a `map` method**, when implemented on a `Container` type, that wraps values of type `T`:

```swift
func map<U>(transformFunction: T -> U) -> Container<U>
```

Let's analyze that signature by looking at the types.
`T` is the type of elements in the current container, `U` will be the type of the elements in the container that will be returned. This allows us to, for example, map an array of strings, to an array of `Int`s that contains the lengths of each of the `String`s in the original array.

We provide a function that takes a `T` value, and returns a value of type `U`. `map` will then use this function to create another `Container` instance, where the original values are replaced by the ones returned by the `transformFunction`.

## Implementing `map` with our own type

Let's implement our own container type. A `Result` enum is a pattern that you will see in a lot of open source Swift code today. [This brings several benefits to an API when used instead of the old Obj-C NSError-by-reference argument](https://gist.github.com/andymatuschak/2b311461caf740f5726f#comment-1364205).

We could define it like this:

```swift
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
```

*The `Box` class is required to work around a current Swift limitation (`unimplemented IR generation feature non-fixed multi-payload enum layout`)*

This is an implementation of a type known as `Either` in some programming languages. Only in this case we're forcing one of the types to be an `NSError` instead of being generic, since we're going to use it to report the result of an operation.

Conceptually, `Result` is very similar to `Optional`: it wraps a value of an arbitrary type, that may or may not be present. In this case, however, it may additional tell us why the value is not there.

To see an example, let's implement a function that reads the contents of a file and returns the result as a `Result` object:

```swift
func dataWithContentsOfFile(file: String, encoding: NSStringEncoding) -> Result<NSData> {
  var error: NSError?

  if let data = NSData(contentsOfFile: file, options: .allZeros, error: &error) {
    return .Value(Box(data))
  }
  else {
    return .Error(error!)
  }
}
```

Easy enough. This function will return *either* an `NSData` object, or an `NSError` in case the file can't be read.

Like we did before, we may want to apply some transformation to the read value. However, like in the case before, we would need to check that we have a value every step of the way, which may result in ugly nested `if let`s or `switch` statements. Let's leverage `map` like we did before. In this case, we will only want to apply such transformation if we have a value. If we don't, we can simply pass the same error through.

Imagine that we wanted to read a file with string contents. We would get an `NSData`, that then we need to transform into a `String`. Then say that we want to turn it into uppercase:

```
NSData -> String -> String
```

We can do this with a series of `map` transformations:

```swift
let data: Result<NSData> = dataWithContentsOfFile(path, NSUTF8StringEncoding)

let uppercaseContents: Result<String> = data.map { NSString(data: $0, encoding: NSUTF8StringEncoding)! }.map { $0.uppercaseString }
```

Similar to the early example with `map` on `Array`s, this code is a lot more expressive. It simply declares what we want to accomplish, with no boilerplate.

In comparison, this is what the above code would look like without the use of `map`:

```swift
let data: Result<NSData> = dataWithContentsOfFile(path, NSUTF8StringEncoding)

var stringContents: String?

switch data {
  case let .Value(value):
    stringContents = NSString(data: value.unbox, encoding: NSUTF8StringEncoding)
  case let .Error(error):
    break
}

let uppercaseContents: String? = stringContents?.uppercaseString
```

How would `Result.map` be implemented? Let's take a look:

```swift
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
```

Again, the transformation function `f` takes a value of type `T` (in the above example, `NSData`) and returns a value of type `U` (`String`). After calling `map`, we'll get a `Result<U>` (`Result<String>`) from an initial `Result<T>` (`Result<NSData>`).
We only call `f` whenever we start with a value, and we simply return another `Result` with the same error otherwise.

## Functors

We've seen what `map` can do when implemented on a container type, like `Optional`, `Array` or `Result`. To recap, it allows us to get a new container, where the value(s) wrapped inside are transformed according to a function.
So **what's a Functor** you may ask? A Functor is any type that implements `map`. That's the whole story.

Once you know what a functor is, we can talk about some types like `Dictionary` or even closures, and by saying that they're functors, you will immediately know of something you can do with them.

## Monads

In the earlier example, we used the transformation function to return another *value*, but what if we wanted to use it to return a new `Result` object? Put another way, what if the transformation operation that we're passing to `map` can fail with an error as well? Let's look at what the types would look like.

```swift
func map<U>(f: T -> U) -> Result<U>
```

In our example, `T` is an `NSData` that we're converting into `U`, a `Result<String>`. So let's replace that in the signature:

```swift
func map(f: NSData -> Result<String>) -> Result<Result<String>>
```

Notice the nested `Result`s in the return type. This is probably not what we'll want. But it's OK. We can implement a function that takes the nested `Result`, and *flattens* it into a simple `Result`:

```swift
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
```

This `flatten` function takes a nested `Result` with a `T` inside, and return a single `Result<T>` simply by extracting the inner object inside the `Value`, or the `Error`.

A `flatten` function can be found in other contexts. For example, one can `flatten` an array of arrays into a contigous, one-dimensional array.

With this, we can implement our `Result<NSData> -> Result<String>` transformation by combining `map` and `flatten`:

```swift
let stringResult = Result<String>.flatten(data.map { (data: NSData) -> (Result<String>) in
  if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
    return Result.Value(Box(string))
  }
  else {
    return Result<String>.Error(NSError(domain: "com.javisoto.es.error_domain", code: JSErrorCodeInvalidStringData, userInfo: nil))
  }
})
```

This is so common, that you will find this defined in many places as `flatMap` or `flattenMap`, which we could implement for `Result` like this:

```swift
extension Result {
  func flatMap<U>(f: T -> Result<U>) -> Result<U> {
      return Result.flatten(map(f))
  }
}
```

And with that, we turned our `Result` type into a Monad! **A Monad is a type of Functor. A type which, along with `map`, implements a `flatMap` function** (*sometimes also known as `bind`*) with a signature similar to the one we've seen here. Container types like the ones we presented here are usually Monads, but you will also see that pattern for example in types that encapsulate deferred computation, like `Signal` or `Future`.

The words **Functor** and **Monad** come from category theory, with which I'm not familiar at all. However, there's value in having names to refer to these concepts. Computer scientists love to come up with names for things. But it's those names that allow us to refer to abstract concepts (*some extremely abstract, like Monad*), and immediately know what we mean (of course, assuming we have the previous knowledge of their meaning). We get the same benefit out of sharing names for things like design patterns (decorator, factory...).

It took me a very long time to assimilate all the ideas in this blog post, so if you're not familiar with any of this I don't expect you to finish reading this and immediately understand it.
However, I encourage you to create an Xcode playground and try to come up with the implementation for `map`, `flatten` and `flatMap` for `Result` or a similar container type (perhaps try with `Optional` or even `Array`), and use some sample values to play with them.

And next time you hear the words Functor or Monad, don't be scared :) They're simply design patterns to describe common operations that we can perform on different types.

*Open source version of the article, where you can create an issue to ask a question or open pull requests: [https://github.com/JaviSoto/Blog-Posts/blob/master/Functor%20and%20Monad%20in%20Swift/FunctorAndMonad.md](https://github.com/JaviSoto/Blog-Posts/blob/master/Functor%20and%20Monad%20in%20Swift/FunctorAndMonad.md)*
