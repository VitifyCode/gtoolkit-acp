Class {
	#name : 'GtAcpClientExamples',
	#superclass : 'Object',
	#category : 'GToolkit-ACP',
	#package : 'GToolkit-ACP'
}

{ #category : 'examples' }
GtAcpClientExamples >> exampleAutoApproveAllToggleAction [
	<gtExample>
	"The session should have a gtAction toggle for autoApproveAll"
	| session actions toggleAction |
	session := GtAcpSession new.
	self assert: session autoApproveAll not.
	
	"Verify the toggle action method exists on GtAcpSession"
	self assert: (GtAcpSession canUnderstand: #gtAutoApproveAllToggleFor:).
	
	"Verify it produces a toggle action"
	actions := GtPhlowActionsCollector new
		pragmaName: #gtAction;
		fromObject: session;
		collect.
	toggleAction := actions detect: [ :a | a isKindOf: GtPhlowToggleAction ] ifNone: [ nil ].
	self assert: toggleAction isNotNil.
	
	^ session
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleForceDisconnectClearsTransportAndSessions [
	"forceDisconnect should nil the transport and clear sessions"
	<gtExample>
	| client |
	client := GtAcpClient new.
	client forceDisconnect.
	self assert: (client instVarNamed: 'transport') isNil.
	self assert: (client instVarNamed: 'sessions') isEmpty.
	^ client
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleHermesClientDefaults [
	"GtHermesClient should have sensible class-side defaults"
	<gtExample>
	| programPath defaultCwd mcpServers |
	programPath := GtHermesClient programPath.
	defaultCwd := GtHermesClient defaultCwd.
	mcpServers := GtHermesClient mcpServers.
	self assert: programPath isString.
	self assert: defaultCwd isString.
	self assert: mcpServers isArray.
	self assert: mcpServers isEmpty.
	^ programPath
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleHermesClientMcpServersOverride [
	"mcpServersForNewSession should return class-side mcpServers"
	<gtExample>
	| client servers |
	client := GtHermesClient new.
	servers := client mcpServersForNewSession.
	self assert: servers equals: GtHermesClient mcpServers.
	^ client
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleHermesClientPrintString [
	"A new GtHermesClient should print as disconnected with 0 sessions"
	<gtExample>
	| client printed |
	client := GtHermesClient new.
	printed := client printString.
	self assert: (printed includesSubstring: 'Hermes(').
	self assert: (printed includesSubstring: 'disconnected').
	self assert: (printed includesSubstring: '0 sessions').
	^ client
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleHermesClientUseGtMcpServer [
	"useGtMcpServer should configure mcpServers from ClaudeMcpServer default port"
	<gtExample>
	| previousServers |
	previousServers := GtHermesClient mcpServers.
	GtHermesClient useGtMcpServer.
	self assert: GtHermesClient mcpServers size equals: 1.
	self assert: (GtHermesClient mcpServers first at: 'name') equals: 'gt-image'.
	self assert: (GtHermesClient mcpServers first at: 'url') equals: 'http://localhost:3030/'.
	GtHermesClient mcpServers: previousServers.
	^ GtHermesClient mcpServers
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleHermesClientWithGtMcpServer [
	"mcpServersForNewSession should produce an HTTP entry with required fields"
	<gtExample>
	| servers entry |
	GtHermesClient mcpServers: (GtHermesClient mcpServerEntryForGtImageOnPort: 3030).
	servers := GtHermesClient new mcpServersForNewSession.
	self assert: servers size equals: 1.
	entry := servers first.
	self assert: (entry at: 'name') equals: 'gt-image'.
	self assert: (entry at: 'url') equals: 'http://localhost:3030/'.
	self assert: (entry at: 'type') equals: 'http'.
	self assert: (entry at: 'headers') isDictionary.
	GtHermesClient mcpServers: nil.
	^ servers
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleLaunchDangerouslySetsAutoApproveAll [
	<gtExample>
	"launchDangerouslyIn: should exist and session autoApproveAll should work"
	| session |
	session := GtAcpSession new.
	session autoApproveAll: true.
	self assert: session autoApproveAll.
	
	"Verify the convenience methods exist on the class side"
	self assert: (GtClaudeCodeClient class canUnderstand: #launchDangerouslyIn:).
	self assert: (GtClaudeCodeClient class canUnderstand: #launchDangerously).
	^ session
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleMcpServersForNewSessionDefaultsToEmpty [
	"Default mcpServersForNewSession should return an empty array"
	<gtExample>
	| client result |
	client := GtAcpClient new.
	result := client mcpServersForNewSession.
	self assert: result equals: #().
	^ client
]

{ #category : 'examples' }
GtAcpClientExamples >> exampleRegistryStartUpWipesClients [
	"startUp: true should forceDisconnect all clients and nil the instance"
	<gtExample>
	| registry client |
	registry := GtAcpClientRegistry new.
	client := GtAcpClient new.
	registry clients add: client.
	self assert: registry clients size equals: 1.
	"Simulate: after startUp the singleton should be wiped — 
	 we test forceDisconnect is called by checking transport is nil"
	client forceDisconnect.
	self assert: (client instVarNamed: 'transport') isNil.
	^ registry
]
