Class {
	#name : 'GtAcpMessageElementExamples',
	#superclass : 'Object',
	#category : 'GToolkit-ACP-Examples',
	#package : 'GToolkit-ACP-Examples'
}

{ #category : 'examples' }
GtAcpMessageElementExamples >> exampleMarkdownRendering [
	<gtExample>
	| assistantMsg element |
	assistantMsg := GtAcpMessage new
		role: 'assistant';
		appendText: '# Python Decorators

A **decorator** is a function that takes another function and extends its behavior. They use the `@` syntax.

## Basic Example

```python
def my_decorator(func):
    def wrapper():
        print("Before call")
        func()
        print("After call")
    return wrapper

@my_decorator
def say_hello():
    print("Hello!")
```

## Key Points

- Decorators *wrap* a function to modify its behavior
- The `@decorator` syntax is **syntactic sugar** for `func = decorator(func)`
- Common built-in decorators: `@property`, `@staticmethod`, `@classmethod`';
		markComplete;
		yourself.
	
	element := GtAcpMessageElement new.
	element message: assistantMsg.
	^ element
]

{ #category : 'examples' }
GtAcpMessageElementExamples >> exampleUserMessagePlainText [
	<gtExample>
	"User messages should NOT get markdown styling"
	| userMsg element |
	userMsg := GtAcpMessage new
		role: 'user';
		appendText: 'Explain **decorators** in Python with `code`';
		markComplete;
		yourself.
	
	element := GtAcpMessageElement new.
	element message: userMsg.
	^ element
]
