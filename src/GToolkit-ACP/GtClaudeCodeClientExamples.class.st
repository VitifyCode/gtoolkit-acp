Class {
	#name : 'GtClaudeCodeClientExamples',
	#superclass : 'Object',
	#category : 'GToolkit-ACP',
	#package : 'GToolkit-ACP'
}

{ #category : 'examples' }
GtClaudeCodeClientExamples >> exampleMcpServersForNewSessionEnsuresMcpRunning [
	"mcpServersForNewSession should ensure the ClaudeMcpServer is running and return its config"
	<gtExample>
	| client servers entry |
	client := GtClaudeCodeClient new.
	servers := client mcpServersForNewSession.
	self assert: servers size equals: 1.
	entry := servers first.
	self assert: (entry at: 'name') equals: 'gt-image'.
	self assert: (entry at: 'type') equals: 'http'.
	self assert: ((entry at: 'url') includesSubstring: 'localhost').
	self assert: ClaudeMcpServer default isRunning.
	^ servers
]
