Class {
	#name : 'GtAcpTransportExamples',
	#superclass : 'Object',
	#category : 'GToolkit-ACP-Examples',
	#package : 'GToolkit-ACP-Examples'
}

{ #category : 'examples' }
GtAcpTransportExamples >> exampleBackgroundTaskDetectsCompletion [
	<gtExample>
	"A background task with an outputPath should detect completion 
	 when no process holds the file open"
	| session task tmpFile |
	session := GtAcpSession new.
	
	"Create a temp file to simulate the output path"
	tmpFile := FileReference newTempFilePrefix: 'gt-bg-test-' suffix: '.output'.
	tmpFile writeStreamDo: [ :s | s nextPutAll: 'done' ].
	
	"Register a background task with that output path"
	task := Dictionary new
		at: 'taskId' put: 'test-task';
		at: 'toolCallId' put: 'tool-1';
		at: 'outputPath' put: tmpFile fullName;
		yourself.
	session backgroundTasks add: task.
	
	"Poll should detect completion (no process has file open)"
	session pollBackgroundTaskCompletion: task.
	
	self assert: (task at: 'status') equals: 'completed'.
	
	tmpFile ensureDelete.
	^ session
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleHandleProcessExitReentrancyGuard [
	"Calling handleProcessExit twice should only fire error handlers once"
	<gtExample>
	| transport callCount |
	transport := GtAcpTransport new.
	callCount := 0.
	(transport instVarNamed: 'errorHandlers') at: 'test' put: [ :msg | callCount := callCount + 1 ].
	"First call sets exiting := true"
	transport handleProcessExit.
	50 milliSeconds wait. "let the fork run"
	"Second call should be guarded"
	transport handleProcessExit.
	50 milliSeconds wait.
	self assert: callCount equals: 1.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleHandleStderrDoesNotError [
	"handleStderr: should accept a string without error (default discards)"
	<gtExample>
	| transport |
	transport := GtAcpTransport new.
	transport handleStderr: 'some error output'.
	"No error means success — default implementation discards stderr"
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleInitializeSetsExitingFalse [
	<gtExample>
	| transport |
	transport := GtAcpTransport new.
	self assert: (transport instVarNamed: 'exiting') equals: false.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> examplePrePopulatedUserMessageDoesNotDouble [
	<gtExample>
	"Regression: a complete user message followed by a new user_message_chunk 
	 from the server echo should be ignored, not create a second message."
	| session |
	session := GtAcpSession new.
	
	"Add a completed user message (as from prompt:inSession:do:onError:)"
	session messages add: (GtAcpMessage user: 'First message').
	session messages last markComplete.
	
	"Server echoes back user_message_chunk — should be ignored"
	session processUpdate: (Dictionary new
		at: 'sessionUpdate' put: 'user_message_chunk';
		at: 'content' put: (Dictionary new
			at: 'type' put: 'text';
			at: 'text' put: 'First message';
			yourself);
		yourself).
	
	self assert: session messages size equals: 1.
	self assert: session messages first contentItems first text equals: 'First message'.
	^ session
]

{ #category : 'examples' }
GtAcpTransportExamples >> examplePromptDoesNotDuplicateUserMessage [
	<gtExample>
	"Client-added user message should be marked complete so server echo is ignored"
	| session |
	session := GtAcpSession new.
	
	"Simulate what prompt:inSession:do:onError: does"
	session messages add: (GtAcpMessage user: 'Hello world').
	session messages last markComplete.
	
	"Simulate server echoing back user_message_chunk"
	session processUpdate: (Dictionary new
		at: 'sessionUpdate' put: 'user_message_chunk';
		at: 'content' put: (Dictionary new
			at: 'type' put: 'text';
			at: 'text' put: 'Hello world';
			yourself);
		yourself).
	
	"Should still be 1 message with original text, not doubled"
	self assert: session messages size equals: 1.
	self assert: session messages first contentItems first text equals: 'Hello world'.
	^ session
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleSessionTracksBackgroundTask [
	<gtExample>
	| session toolCallDict updateDict |
	session := GtAcpSession new.
	
	"First register a tool call"
	toolCallDict := Dictionary new
		at: 'toolCallId' put: 'tool-123';
		at: 'title' put: 'Monitor CI build';
		at: 'kind' put: 'execute';
		at: 'status' put: 'pending';
		at: 'content' put: #();
		at: 'rawInput' put: Dictionary new;
		at: 'sessionUpdate' put: 'tool_call';
		yourself.
	session processUpdate: toolCallDict.
	
	"Then send a tool_call_update with backgroundTaskId"
	updateDict := Dictionary new
		at: 'sessionUpdate' put: 'tool_call_update';
		at: 'toolCallId' put: 'tool-123';
		at: 'status' put: 'completed';
		at: '_meta' put: (Dictionary new
			at: 'claudeCode' put: (Dictionary new
				at: 'toolResponse' put: (Dictionary new
					at: 'backgroundTaskId' put: 'abc123';
					at: 'stdout' put: '';
					yourself);
				yourself);
			yourself);
		yourself.
	session processUpdate: updateDict.
	
	self assert: session backgroundTasks isNotEmpty.
	self assert: (session backgroundTasks first at: 'taskId') equals: 'abc123'.
	self assert: (session backgroundTasks first at: 'toolCallId') equals: 'tool-123'.
	^ session
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleSessionTracksBackgroundTaskOutputPath [
	<gtExample>
	| session toolCallDict updateDict contentUpdateDict |
	session := GtAcpSession new.
	
	"Register a tool call"
	toolCallDict := Dictionary new
		at: 'toolCallId' put: 'tool-456';
		at: 'title' put: 'Monitor build';
		at: 'kind' put: 'execute';
		at: 'status' put: 'pending';
		at: 'content' put: #();
		at: 'rawInput' put: Dictionary new;
		at: 'sessionUpdate' put: 'tool_call';
		yourself.
	session processUpdate: toolCallDict.
	
	"Update with backgroundTaskId"
	updateDict := Dictionary new
		at: 'sessionUpdate' put: 'tool_call_update';
		at: 'toolCallId' put: 'tool-456';
		at: '_meta' put: (Dictionary new
			at: 'claudeCode' put: (Dictionary new
				at: 'toolResponse' put: (Dictionary new
					at: 'backgroundTaskId' put: 'xyz789';
					at: 'stdout' put: '';
					yourself);
				yourself);
			yourself);
		yourself.
	session processUpdate: updateDict.
	
	"Update with content containing output path"
	contentUpdateDict := Dictionary new
		at: 'sessionUpdate' put: 'tool_call_update';
		at: 'toolCallId' put: 'tool-456';
		at: 'content' put: { Dictionary new
			at: 'type' put: 'content';
			at: 'content' put: (Dictionary new
				at: 'type' put: 'text';
				at: 'text' put: '```console
Command running in background with ID: xyz789. Output is being written to: /tmp/tasks/xyz789.output
```';
				yourself);
			yourself };
		yourself.
	session processUpdate: contentUpdateDict.
	
	self assert: session backgroundTasks size equals: 1.
	self assert: (session backgroundTasks first at: 'outputPath') equals: '/tmp/tasks/xyz789.output'.
	^ session
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleStartSetsUpStderrHandler [
	"After start, stderrHandler should be non-nil"
	<gtExample>
	| transport |
	transport := self startedTransportWithCat.
	self assert: (transport instVarNamed: 'stderrHandler') isNotNil.
	transport terminate.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> exampleTerminateCleansUpStderrHandler [
	"After terminate, stderrHandler should be nil"
	<gtExample>
	| transport |
	transport := self startedTransportWithCat.
	self assert: (transport instVarNamed: 'stderrHandler') isNotNil.
	transport terminate.
	self assert: (transport instVarNamed: 'stderrHandler') isNil.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> requestResponseRoundtrip [
	"Send a JSON-RPC request to a shell script that reads it and sends back a proper result response.
	Tests the resultHandlers path."
	<gtExample>
	| transport result semaphore errorOccurred |
	transport := GtAcpTransport
		on: '/bin/bash'
		args: #('-c' 'while IFS= read -r line; do id=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin)[''id''])"); echo "{\"jsonrpc\":\"2.0\",\"id\":$id,\"result\":{\"status\":\"ok\"}}"; done').
	transport start.
	result := nil.
	errorOccurred := false.
	semaphore := Semaphore new.
	transport
		sendRequest: 'test/echo'
		params: (Dictionary new at: 'hello' put: 'world'; yourself)
		do: [ :res |
			result := res.
			semaphore signal ]
		onError: [ :err |
			errorOccurred := true.
			semaphore signal ].
	semaphore waitTimeoutSeconds: 5.
	self assert: errorOccurred not.
	self assert: result notNil.
	self assert: (result at: 'status') equals: 'ok'.
	transport terminate.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> respondToServerRequest [
	"Test server→client request handling and respondTo:result:.
	Uses a bash script that sends a JSON-RPC request to the client, then reads the client's response.
	The script sends back the client's response as a notification so we can verify it."
	<gtExample>
	| transport receivedResponse semaphore script |
	script := 'echo ''{"jsonrpc":"2.0","id":99,"method":"test/question","params":{"q":"answer?"}}''; IFS= read -r response; id=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[''id''])"); result=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps(d[''result'']))"); echo "{\"jsonrpc\":\"2.0\",\"method\":\"test/got_response\",\"params\":$result}"'.
	transport := GtAcpTransport on: '/bin/bash' args: { '-c'. script }.
	receivedResponse := nil.
	semaphore := Semaphore new.
	"Register handler for the server→client request"
	transport on: 'test/question' do: [ :params :fullMessage |
		transport respondTo: (fullMessage at: 'id') result: (Dictionary new at: 'answer' put: 'yes'; yourself) ].
	"Register handler to capture what the server got back"
	transport on: 'test/got_response' do: [ :params |
		receivedResponse := params.
		semaphore signal ].
	transport start.
	semaphore waitTimeoutSeconds: 5.
	self assert: receivedResponse notNil.
	self assert: (receivedResponse at: 'answer') equals: 'yes'.
	transport terminate.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> roundtripWithCat [
	"Send a JSON-RPC notification through cat and verify it echoes back via method handler.
	cat echoes stdin to stdout — so the message arrives back with its 'method' key,
	routing it to methodHandlers."
	<gtExample>
	| transport received semaphore |
	transport := self startedTransportWithCat.
	received := nil.
	semaphore := Semaphore new.
	transport on: 'test/ping' do: [ :params |
		received := params.
		semaphore signal ].
	transport sendNotification: 'test/ping' params: (Dictionary new at: 'value' put: 42; yourself).
	semaphore waitTimeoutSeconds: 2.
	self assert: received notNil.
	self assert: (received at: 'value') equals: 42.
	transport terminate.
	self assert: transport isRunning not.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> startedTransportWithCat [
	"Start a cat transport — should be running"
	<gtExample>
	| transport |
	transport := self transportWithCat.
	transport start.
	self assert: transport isRunning.
	^ transport
]

{ #category : 'examples' }
GtAcpTransportExamples >> transportWithCat [
	"Spawn cat as a subprocess — it echoes stdin back to stdout"
	<gtExample>
	| transport |
	transport := GtAcpTransport on: '/bin/cat'.
	self assert: transport isRunning not.
	self assert: transport program equals: '/bin/cat'.
	^ transport
]
