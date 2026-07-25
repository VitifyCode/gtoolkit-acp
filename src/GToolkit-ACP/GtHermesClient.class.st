Class {
	#name : 'GtHermesClient',
	#superclass : 'GtAcpClient',
	#classInstVars : [
		'programPath',
		'defaultCwd',
		'mcpServers'
	],
	#category : 'GToolkit-ACP',
	#package : 'GToolkit-ACP'
}

{ #category : 'configuration' }
GtHermesClient class >> defaultCwd [
	^ defaultCwd ifNil: [ FileLocator home fullName ]
]

{ #category : 'configuration' }
GtHermesClient class >> defaultCwd: aString [
	defaultCwd := aString
]

{ #category : 'launching' }
GtHermesClient class >> launch [
	^ self launchIn: self defaultCwd
]

{ #category : 'launching' }
GtHermesClient class >> launchIn: aCwdString [
	| client |
	client := self new.
	client connect.
	client initializeDo: [ :result |
		client newSessionIn: aCwdString do: [ :session | ]
		onError: [ :err | Transcript crShow: 'Session error: ', err printString ] ]
	onError: [ :err | Transcript crShow: 'Init error: ', err printString ].
	^ client
]

{ #category : 'configuration' }
GtHermesClient class >> mcpServerEntryForGtImageOnPort: aPort [
	"Build an ACP-compatible mcpServers array with an HTTP entry
	pointing at a ClaudeMcpServer running on aPort."
	^ { Dictionary new
		at: 'name' put: 'gt-image';
		at: 'type' put: 'http';
		at: 'url' put: 'http://localhost:', aPort asString, '/';
		at: 'headers' put: Dictionary new;
		yourself }
]

{ #category : 'configuration' }
GtHermesClient class >> mcpServers [
	"MCP servers to register with each new session.
	Each entry: Dictionary with keys name, command, args (Array), env (Dictionary)."
	^ mcpServers ifNil: [ #() ]
]

{ #category : 'configuration' }
GtHermesClient class >> mcpServers: anArray [
	mcpServers := anArray
]

{ #category : 'configuration' }
GtHermesClient class >> programPath [
	^ programPath ifNil: [ '/usr/local/bin/hermes' ]
]

{ #category : 'configuration' }
GtHermesClient class >> programPath: aString [
	programPath := aString
]

{ #category : 'configuration' }
GtHermesClient class >> useGtMcpServer [
	"Configure Hermes to use the GT image MCP server (ClaudeMcpServer) on its default port."
	self mcpServers: (self mcpServerEntryForGtImageOnPort: ClaudeMcpServer new port)
]

{ #category : 'connecting' }
GtHermesClient >> connect [
	self
		connectTo: self class programPath
		args: #('acp')
		environment: Dictionary new
]

{ #category : 'protocol' }
GtHermesClient >> mcpServersForNewSession [
	^ self class mcpServers
]

{ #category : 'printing' }
GtHermesClient >> printOn: aStream [
	aStream
		nextPutAll: 'Hermes(';
		nextPutAll: (self isConnected ifTrue: [ 'connected' ] ifFalse: [ 'disconnected' ]);
		nextPutAll: ' - ';
		print: sessions size;
		nextPutAll: ' sessions';
		nextPut: $)
]
