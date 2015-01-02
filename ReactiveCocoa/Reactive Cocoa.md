# Reactive Cocoa

A lot is being written these days about Reactive Cocoa and the paradigms it introduces. In my opinion, there are only two sides giving their opinion: the ones that know a lot about it and are therefore obviously biased, and the ones that refuse to learn it.

I decided to write something myself because I think I'm right in the middle. Some months ago I knew nothing about it, and now I know enough to want to use it every day. I hope that by not being an expert, I can actual introduce a few really simple ideas in a much easier way to pick up by new-commers, to show why I think Reactive Cocoa is an incredibly powerful tool to help us write better, cleaner, and more maintainable code.

### Signals

The base of **everything** that happens in Reactive Cocoa is signals. I'm going to try to explain what they *represent* and why they fit in the way we think about what happens on an app. A lot of the things you may read about Functional Reactive Programming end up confusing you when they introduce more advanced FP operators, etc. So let's avoid that.

What is a signal? Think of it as a pipe that carries values. This flow of values is actually present everywhere in our apps when you think about it: the data downloaded from the network, the Boolean value "is the user logged in", the value of a setting "font size across the app", etc. Most values are not constant, they vary over time, and we manage that in a number of ways: callbacks, delegates, KVO, NSNotificationCenter....

Why is something like signals, which clearly represent a *real thing* and not some crazy mathematical model, not present in our language / frameworks / design patterns? Because the inherent C-way-of-doing-things rules the way we write code. Apart from the Object Orientation abstractions, the imperative code that we write isn't very far from Assembly: we feed instructions to the machine, and it executes them one by one, sequentially. We have to manage the data that it reads / writes in memory (state). i.e when we write imperative code, we tell the machine **how** to do the work, instead of **what** work to do. This is what a new paradigm tries to accomplish: to drive us away from this low-level universe into a place closer to the way we reason and express our intentions when writing code.

Now think about something for a second. Say you call a method that returns some data, let's say a list of tweets. It doesn't return the *present* value, by the time the method returns, that's already the *past*. Just like the way our eyes don't observe the present but some not-very-distant past. But this is not a problem, you may think, whenever the list of tweets changes, we'll call the method again to feed the new list to our table view. I know! I'll use a delegate! Right? Right...? But what if we had an entity, a *thing* that represented exactly that: a flow of values that change over time.

So let me introduce **one** construct that I hope will make you want to use Reactive Cocoa even if just for that.

Let's say we want a signal that will carry the values of this list of tweets. Assuming that we have a JASTweetDataProvider class with a property like this:

```objc
@property (nonatomic, readonly, strong) NSArray *tweets;
```

That is set whenever some other component queries the Twitter API and therefor sends KVO notifications. Reactive Cocoa makes it incredibly easy to get a signal that will send values (in this case, NSArrays) every time the propery changes:

```objc
RACObserve(self.tweetDataProvider, tweets);
```

(Note the awesomeness of ReactiveCocoa handling the KVO subscription for us and removing it as soon as self is long to be deallocated, let's say whatever ViewController we're doing this in)

So what we can do with this signal? We can **bind** its values to something else. Look over the code of the last 5 view controllers you worked on and ping me on Twitter if you don't think that 90% of the code there is glue-code to change some value whenever other value changes through some callback mechanism. The problem with this code is that it tends to be kind of spaghetti-y: there's the observations in one place, the values coming in in another, and then the processing of the values somewhere else. We're used to code like this, but we can't deny its complexity. Again: we focus on **how** the task has to be accomplished and not the **what** we're trying to do. And then there's all the underlying trickiness not obvious at first, common source of bugs: "is this happening in the right order". This forces us to use the debugger to analyze the state of the view controller, see what method gets called first, etc. Gross.

So let's go back to our example. How do we bind our ever-changing list of tweets to something else? With a one liner.

```objc
RAC(self.tableDataSource, tweets) = RACObserve(self.tweetDataProvider, tweets);
```

* When I started using Reactive Cocoa it helped me a lot to read the RAC() macro as "RACBind". So you could read this line as "Bind the tweets coming from the data provider into the table view."

And before you start thinking "ah, magical code that abuses pre-processor macros", think about what we have achieved. I don't have to jump back and forth between 3 methods to understand what the flow of data is. This line is so descriptive that one can read it and forget about the implementation details and focus on the **what**. You can forget about whether the stringly-typed keypath is correct or has a typo, whether you're implementing KVO right or your breaking your parent class, you can forget about forgetting to unsubscribe, unsubscribing without having subscribed, and a long etc. And you can simply wonder "did I tell my code to do what I want it to do?". Honestly, since I use Reactive Cocoa I sleep better at night.

And because you may say that this is a dumb example, I'm going to show one last example. And if you think that we don't need to use KVO for that and we could've used a protocol, think about the fact that we get being KVO-complaint for free in almost all cases and creating a protocol requires a lot of boiler-plate code.

So say we want to show or hide a label that says "no tweets" depending on whether there are any tweets or not. I'm sure you're drawing the graph of method calls in your head to accomplish this. Or maybe you're imagining the growing - observeValueForKeyPath:ofObject:change:context:. Check out this descriptive code:

```objc
RAC(self.noTweetsLabel, hidden) = [RACObserve(self.tweetDataProvider, tweets) map:NSNumber *^(NSArray *tweets) {
	return @(tweets.count > 0);
}];
```

When you call `-map:` on a signal, it returns another signal that gets a value every time the original signal gets a value, but "maps" them to another value. In this case we're converting NSArray values into boolean (*isHidden*?) values.


If I have convinced you to at least give Reactive Cocoa a try, I would be very satisfied. But maybe you simply have to trust me when I tell you that you need to try it out for yourself to realize how incredibly useful it is.
