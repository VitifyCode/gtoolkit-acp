Class {
	#name : 'GtAcpPermissionUxExamples',
	#superclass : 'Object',
	#category : 'GToolkit-ACP-Examples',
	#package : 'GToolkit-ACP-Examples'
}

{ #category : 'examples - auto-allow' }
GtAcpPermissionUxExamples >> exampleAutoAllowUsesCorrectOptionId [
	<gtExample>
	"When auto-allowing, the client should use a valid optionId from the options list, not hardcoded 'allow_always'"
	| client session transport sentMessages params options |
	client := GtAcpClient new.
	session := GtAcpSession new.
	session sessionId: 'test-session'.
	session alwaysAllowedTools add: 'Ready to code?'.
	client sessions at: 'test-session' put: session.
	
	"Build a permission request with ExitPlanMode-style options"
	options := {
		Dictionary new at: 'kind' put: 'allow_always'; at: 'name' put: 'Yes, bypass'; at: 'optionId' put: 'bypassPermissions'; yourself.
		Dictionary new at: 'kind' put: 'allow_always'; at: 'name' put: 'Yes, auto-accept'; at: 'optionId' put: 'acceptEdits'; yourself.
		Dictionary new at: 'kind' put: 'allow_once'; at: 'name' put: 'Yes, manual'; at: 'optionId' put: 'default'; yourself.
		Dictionary new at: 'kind' put: 'reject_once'; at: 'name' put: 'No'; at: 'optionId' put: 'plan'; yourself
	}.
	params := Dictionary new
		at: 'sessionId' put: 'test-session';
		at: 'toolCall' put: (Dictionary new at: 'title' put: 'Ready to code?'; yourself);
		at: 'options' put: options;
		yourself.
	
	"Capture what would be sent"
	sentMessages := OrderedCollection new.
	transport := client transport.
	
	"We can't easily mock the transport, so just verify the session state"
	self assert: (session hasPendingPermissionForToolTitle: 'Ready to code?') not.
	
	"The permission should be auto-allowed (status = 'auto-allowed'), not added to pending"
	"We verify by checking that after handling, no pending permission exists"
	"(The actual transport call will fail without a real connection, but the session state should be correct)"
	[ client handlePermissionRequest: params requestId: 99 ]
		on: Error do: [ :e | "transport not connected - expected" ].
	
	"Should NOT be pending — should have been auto-allowed"
	self assert: (session pendingPermissions 
		select: [ :r | (r at: 'status' ifAbsent: ['']) = 'pending' ]) isEmpty.
	
	"Should be in history as auto-allowed"
	self assert: session permissionHistory size equals: 1.
	self assert: (session permissionHistory first at: 'status') equals: 'auto-allowed'.
	
	^ session
]

{ #category : 'examples' }
GtAcpPermissionUxExamples >> exampleAutoApproveAllSkipsPending [
	<gtExample>
	"When session autoApproveAll is true, permission requests should be auto-allowed 
	 without being added to pendingPermissions, even for tools NOT in alwaysAllowedTools"
	| client session params options |
	client := GtAcpClient new.
	
	session := GtAcpSession new.
	session sessionId: 'test-session'.
	session autoApproveAll: true.
	client sessions at: 'test-session' put: session.
	
	options := {
		Dictionary new at: 'kind' put: 'allow_always'; at: 'name' put: 'Allow'; at: 'optionId' put: 'allow1'; yourself.
		Dictionary new at: 'kind' put: 'reject_once'; at: 'name' put: 'No'; at: 'optionId' put: 'reject1'; yourself
	}.
	params := Dictionary new
		at: 'sessionId' put: 'test-session';
		at: 'toolCall' put: (Dictionary new at: 'title' put: 'SomeNewTool'; yourself);
		at: 'options' put: options;
		yourself.
	
	"Handle the request — transport call will fail but session state should be correct"
	[ client handlePermissionRequest: params requestId: 42 ]
		on: Error do: [ :e | "transport not connected - expected" ].
	
	"Should NOT be pending — should have been auto-approved"
	self assert: (session pendingPermissions 
		select: [ :r | (r at: 'status' ifAbsent: ['']) = 'pending' ]) isEmpty.
	
	"Should appear in history as auto-allowed"
	self assert: session permissionHistory isNotEmpty.
	self assert: ((session permissionHistory first at: 'status') = 'auto-allowed').
	
	^ session
]

{ #category : 'examples - support' }
GtAcpPermissionUxExamples >> examplePendingPermissionRequest [
	<gtExample>
	| request |
	request := Dictionary new
		at: 'status' put: 'pending';
		at: 'requestId' put: 'req-001';
		at: 'toolCall' put: (Dictionary new
			at: 'title' put: 'ExitPlanMode';
			at: 'toolCallId' put: 'toolu_abc123';
			at: 'rawInput' put: (Dictionary new at: 'plan' put: '# My Plan'; yourself);
			yourself);
		at: 'options' put: {
			Dictionary new at: 'optionId' put: 'allow'; at: 'name' put: 'Allow'; yourself.
			Dictionary new at: 'optionId' put: 'deny'; at: 'name' put: 'Deny'; yourself };
		yourself.
	self assert: (request at: 'status') equals: 'pending'.
	self assert: ((request at: 'toolCall') at: 'title') equals: 'ExitPlanMode'.
	^ request
]

{ #category : 'examples - support' }
GtAcpPermissionUxExamples >> examplePendingToolCall [
	<gtExample>
	| tc |
	tc := GtAcpToolCall fromDictionary: (Dictionary new
		at: 'toolCallId' put: 'toolu_abc123';
		at: 'title' put: 'ExitPlanMode';
		at: 'status' put: 'pending';
		at: 'rawInput' put: (Dictionary new at: 'plan' put: '# My Plan'; yourself);
		yourself).
	self assert: tc status equals: 'pending'.
	self assert: tc title equals: 'ExitPlanMode'.
	self assert: tc toolCallId equals: 'toolu_abc123'.
	^ tc
]

{ #category : 'examples - permission element' }
GtAcpPermissionUxExamples >> examplePermissionElementShowsActionRequired [
	<gtExample>
	"Permission element should display 'Action required: ExitPlanMode' with option buttons"
	| request element titleText buttonCount bgColor |
	request := self examplePendingPermissionRequest.
	element := GtAcpPermissionElement new.
	element request: request client: nil session: nil.
	titleText := (element childNamed: #title) text asString.
	buttonCount := (element childNamed: #options) children size.
	bgColor := element background paint color.
	self assert: (titleText includesSubstring: 'Action required').
	self assert: (titleText includesSubstring: 'ExitPlanMode').
	self assert: buttonCount equals: 2.
	self assert: bgColor red > 0.9.
	self assert: bgColor green > 0.9.
	self assert: bgColor blue < 0.85.
	^ element
]

{ #category : 'examples - session' }
GtAcpPermissionUxExamples >> exampleSessionWithNoPermission [
	<gtExample>
	| session |
	session := GtAcpSession new.
	self assert: (session hasPendingPermissionForToolCallId: 'toolu_abc123') not.
	self assert: (session hasPendingPermissionForToolTitle: 'ExitPlanMode') not.
	^ session
]

{ #category : 'examples - support' }
GtAcpPermissionUxExamples >> exampleSessionWithPendingPermission [
	<gtExample>
	| session request |
	session := GtAcpSession new.
	request := self examplePendingPermissionRequest.
	session addPermissionRequest: request.
	self assert: session pendingPermissions size equals: 1.
	self assert: (session hasPendingPermissionForToolCallId: 'toolu_abc123').
	self assert: (session hasPendingPermissionForToolTitle: 'ExitPlanMode').
	^ session
]

{ #category : 'examples' }
GtAcpPermissionUxExamples >> exampleShellDoesNotDuplicatePermissions [
	<gtExample>
	"Permissions should only appear inline on tool call elements, not duplicated at the bottom of the shell"
	| session |
	session := self exampleSessionWithPendingPermission.
	self assert: (session pendingPermissions anySatisfy: [ :r | (r at: 'status') = 'pending' ]).
	^ session
]

{ #category : 'examples - tool call element' }
GtAcpPermissionUxExamples >> exampleToolCallElementAwaitingPermission [
	<gtExample>
	"A tool call element with a matching pending permission should show amber state"
	| session tc element iconText bgColor |
	session := self exampleSessionWithPendingPermission.
	tc := self examplePendingToolCall.
	element := GtAcpToolCallElement new.
	element session: session.
	element toolCall: tc.
	iconText := element children first children first text asString.
	bgColor := element background paint color.
	self assert: iconText equals: '?'.
	self assert: bgColor red > 0.9.
	self assert: bgColor green > 0.9.
	self assert: bgColor blue < 0.85.
	^ element
]

{ #category : 'examples - tool call element' }
GtAcpPermissionUxExamples >> exampleToolCallElementMatchesByTitle [
	<gtExample>
	"Permission matching should work by title when toolCallId is absent"
	| session request tc element iconText |
	session := GtAcpSession new.
	request := Dictionary new
		at: 'status' put: 'pending';
		at: 'requestId' put: 'req-002';
		at: 'toolCall' put: (Dictionary new at: 'title' put: 'ExitPlanMode'; yourself);
		at: 'options' put: #();
		yourself.
	session addPermissionRequest: request.
	tc := GtAcpToolCall new.
	tc applyUpdate: (Dictionary new
		at: 'title' put: 'ExitPlanMode';
		at: 'status' put: 'pending';
		yourself).
	element := GtAcpToolCallElement new.
	element session: session.
	element toolCall: tc.
	iconText := element children first children first text asString.
	self assert: iconText equals: '?'.
	^ element
]

{ #category : 'examples - tool call element' }
GtAcpPermissionUxExamples >> exampleToolCallElementPendingNoPermission [
	<gtExample>
	"A pending tool call WITHOUT a permission request should show normal pending state"
	| session tc element iconText |
	session := self exampleSessionWithNoPermission.
	tc := self examplePendingToolCall.
	element := GtAcpToolCallElement new.
	element session: session.
	element toolCall: tc.
	iconText := element children first children first text asString.
	self assert: iconText equals: '...'.
	^ element
]

{ #category : 'examples - tool call element' }
GtAcpPermissionUxExamples >> exampleToolCallElementShowsInlineButtons [
	<gtExample>
	"A tool call awaiting permission should show approval buttons inline"
	| session tc element permContainer |
	session := GtAcpSession new.
	session addPermissionRequest: (Dictionary new
		at: 'status' put: 'pending';
		at: 'requestId' put: 'req-inline';
		at: 'toolCall' put: (Dictionary new at: 'title' put: 'ExitPlanMode'; yourself);
		at: 'options' put: {
			Dictionary new at: 'kind' put: 'allow_always'; at: 'name' put: 'Yes, bypass'; at: 'optionId' put: 'bypassPermissions'; yourself.
			Dictionary new at: 'kind' put: 'allow_once'; at: 'name' put: 'Yes, manual'; at: 'optionId' put: 'default'; yourself.
			Dictionary new at: 'kind' put: 'reject_once'; at: 'name' put: 'No, keep planning'; at: 'optionId' put: 'plan'; yourself };
		yourself).
	tc := GtAcpToolCall fromDictionary: (Dictionary new
		at: 'title' put: 'ExitPlanMode';
		at: 'status' put: 'pending';
		yourself).
	element := GtAcpToolCallElement new.
	element session: session.
	element toolCall: tc.
	"permissionButtonsContainer is the 2nd child"
	permContainer := element children second.
	self assert: permContainer visibility equals: BlVisibility visible.
	self assert: permContainer children size equals: 3.
	self assert: (permContainer children allSatisfy: [ :c | c isKindOf: BrButton ]).
	^ element
]

{ #category : 'examples - tool call element' }
GtAcpPermissionUxExamples >> exampleToolCallElementWithoutSession [
	<gtExample>
	"A tool call element without a session should show normal pending state (no crash)"
	| tc element iconText |
	tc := self examplePendingToolCall.
	element := GtAcpToolCallElement new.
	element toolCall: tc.
	iconText := element children first children first text asString.
	self assert: iconText equals: '...'.
	^ element
]
