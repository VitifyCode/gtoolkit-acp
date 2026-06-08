Class {
	#name : 'GtClaudeCodeClient',
	#superclass : 'GtAcpClient',
	#classInstVars : [
		'programPath',
		'programArgs',
		'defaultCwd',
		'nodeBinPath'
	],
	#category : 'GToolkit-ACP',
	#package : 'GToolkit-ACP'
}

{ #category : 'configuration' }
GtClaudeCodeClient class >> defaultCwd [
	^ defaultCwd ifNil: [ FileLocator home fullName ]
]

{ #category : 'configuration' }
GtClaudeCodeClient class >> defaultCwd: aString [
	defaultCwd := aString
]

{ #category : 'defaults' }
GtClaudeCodeClient class >> defaultEnvironment [
	^ { 'MAX_THINKING_TOKENS' -> '10000' } asDictionary
]

{ #category : 'examples' }
GtClaudeCodeClient class >> exampleDefaultCwdIsPortable [
	"Verify that the default CWD does not contain a hardcoded developer-specific path"
	<gtExample>
	| cwd |
	"Reset to ensure we test the fallback"
	self defaultCwd: nil.
	cwd := self defaultCwd.
	self assert: cwd isNotNil.
	self assert: (cwd includesSubstring: '/Users/user/') not description: 'defaultCwd should not contain a hardcoded developer path'.
	self assert: cwd equals: FileLocator home fullName.
	^ cwd
]

{ #category : 'examples' }
GtClaudeCodeClient class >> exampleProgramArgsIsPortable [
	"Verify that programArgs does not contain a hardcoded developer-specific path"
	<gtExample>
	| args |
	self programArgs: nil.
	args := self programArgs.
	self assert: args isNotNil.
	args do: [ :each |
		self assert: (each includesSubstring: '/Users/user/') not description: 'programArgs should not contain a hardcoded developer path' ].
	^ args
]

{ #category : 'examples' }
GtClaudeCodeClient class >> exampleProgramPathIsPortable [
	"Verify that programPath does not contain a hardcoded developer-specific path"
	<gtExample>
	| path |
	self programPath: nil.
	path := self programPath.
	self assert: path isNotNil.
	self assert: (path includesSubstring: '/Users/user/') not description: 'programPath should not contain a hardcoded developer path'.
	^ path
]

{ #category : 'launching' }
GtClaudeCodeClient class >> launch [
	"Create a new Claude Code client, connect, initialize, and open a session in the default CWD"
	^ self launchIn: self defaultCwd
]

{ #category : 'launching' }
GtClaudeCodeClient class >> launchDangerously [
	"Create a new Claude Code client with auto-approve-all permissions in the default CWD"
	^ self launchDangerouslyIn: self defaultCwd
]

{ #category : 'launching' }
GtClaudeCodeClient class >> launchDangerouslyIn: aCwdString [
	"Create a new Claude Code client, connect, initialize, and open a session 
	 with auto-approve-all permissions in the given CWD."
	| client |
	client := self new.
	client connect.
	client initializeDo: [ :result |
		client newSessionIn: aCwdString do: [ :session |
			session autoApproveAll: true ] onError: [ :err |
			Transcript crShow: 'Session error: ', err printString ] ]
	onError: [ :err |
		Transcript crShow: 'Init error: ', err printString ].
	^ client
]

{ #category : 'instance creation' }
GtClaudeCodeClient class >> launchIn: aCwdString [
	"Create a new Claude Code client, connect, initialize, and open a session in the given CWD.
	Returns the client. The session is created asynchronously."
	| client |
	client := self new.
	client connect.
	client initializeDo: [ :result |
		client newSessionIn: aCwdString do: [ :session | ] onError: [ :err |
			Transcript crShow: 'Session error: ', err printString ] ]
	onError: [ :err |
		Transcript crShow: 'Init error: ', err printString ].
	^ client
]

{ #category : 'accessing' }
GtClaudeCodeClient class >> nodeBinPath [
	"Path to a Node.js bin directory to prepend to PATH.
	The cc-acp SDK (v1.x) crashes on Node 25+. Set this to a Node 22 bin dir if needed.
	Defaults to mise shims directory if it exists."
	^ nodeBinPath ifNil: [
		| miseShims |
		miseShims := FileLocator home / '.local' / 'share' / 'mise' / 'shims'.
		miseShims exists ifTrue: [ miseShims pathString ] ifFalse: [ nil ] ]
]

{ #category : 'accessing' }
GtClaudeCodeClient class >> nodeBinPath: aString [
	"Set the path to a Node.js bin directory to prepend to PATH.
	Example: GtClaudeCodeClient nodeBinPath: '/Users/me/.local/share/mise/installs/node/22.22.3/bin'"
	nodeBinPath := aString
]

{ #category : 'defaults' }
GtClaudeCodeClient class >> programArgs [
	"Arguments for the node process. Defaults to the claude-agent-acp script path."
	^ programArgs ifNil: [ { '/opt/homebrew/lib/node_modules/@agentclientprotocol/claude-agent-acp/dist/index.js' } ]
]

{ #category : 'configuration' }
GtClaudeCodeClient class >> programArgs: anArray [
	programArgs := anArray
]

{ #category : 'defaults' }
GtClaudeCodeClient class >> programPath [
	"Path to the node executable. Uses 'node' from PATH by default."
	^ programPath ifNil: [ 'node' ]
]

{ #category : 'configuration' }
GtClaudeCodeClient class >> programPath: aString [
	programPath := aString
]

{ #category : 'connecting' }
GtClaudeCodeClient >> connect [
	"Connect using the class-side configured program path, args, and environment"
	self connectTo: self class programPath args: self class programArgs environment: self class defaultEnvironment
]

{ #category : 'printing' }
GtClaudeCodeClient >> printOn: aStream [
	aStream 
		nextPutAll: 'ClaudeCode(';
		nextPutAll: (self isConnected ifTrue: [ 'connected' ] ifFalse: [ 'disconnected' ]);
		nextPutAll: ' - ';
		print: sessions size;
		nextPutAll: ' sessions';
		nextPut: $)
]
