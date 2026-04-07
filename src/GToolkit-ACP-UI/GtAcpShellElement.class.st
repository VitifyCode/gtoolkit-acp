Class {
	#name : 'GtAcpShellElement',
	#superclass : 'BlElement',
	#instVars : [
		'client',
		'session',
		'listElement',
		'inputElement',
		'statusLabel',
		'cancelButton',
		'modeButton',
		'statusBar',
		'permissionContainer',
		'subscriber',
		'lastMessageCount'
	],
	#category : 'GToolkit-ACP-UI',
	#package : 'GToolkit-ACP-UI'
}

{ #category : 'instance creation' }
GtAcpShellElement class >> on: aClient session: aSession [
	^ self new
		client: aClient session: aSession;
		yourself
]

{ #category : 'actions' }
GtAcpShellElement >> cancelPrompt [
	session ifNil: [ ^ self ].
	client cancelSession: session.
	cancelButton visibility: BlVisibility gone.
	statusLabel text: 'Cancelled'
]

{ #category : 'accessing' }
GtAcpShellElement >> client [
	^ client
]

{ #category : 'accessing' }
GtAcpShellElement >> client: aGtAcpClient session: aGtAcpSession [
	client := aGtAcpClient.
	session := aGtAcpSession.
	lastMessageCount := -1.
	self subscribeToSession.
	self updateStatus.
	self updateMessages
]

{ #category : 'actions' }
GtAcpShellElement >> cycleModes [
	| modes currentIdx nextMode |
	session ifNil: [ ^ self ].
	modes := session availableModes.
	(modes isNil or: [ modes isEmpty ]) ifTrue: [ ^ self ].
	currentIdx := modes detectIndex: [ :m | (m at: 'id') = session currentModeId ] ifNone: [ 0 ].
	nextMode := modes at: (currentIdx \\ modes size + 1).
	client setMode: (nextMode at: 'id') inSession: session 
		do: [ :result |
			session currentModeId: (nextMode at: 'id').
			self enqueueTask: (BlTaskAction new action: [ self updateStatus ]) ]
		onError: [ :err |
			self enqueueTask: (BlTaskAction new action: [ 
				statusLabel text: ('Mode error: ' , err printString) ]) ]
]

{ #category : 'initialization' }
GtAcpShellElement >> initialize [
	super initialize.
	subscriber := Object new.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical matchParent ].
	self padding: (BlInsets all: 5).
	self initializeListElement.
	self initializePermissionContainer.
	self initializeInputElement.
	self initializeStatusBar.
	self addChild: listElement as: #list.
	self addChild: permissionContainer as: #permissions.
	self addChild: inputElement as: #input.
	self addChild: statusBar as: #status
]

{ #category : 'initialization' }
GtAcpShellElement >> initializeInputElement [
	inputElement := BrEditor new
		hMatchParent;
		vFitContentLimited;
		padding: (BlInsets all: 8);
		border: (BlBorder paint: BrGlamorousColors lightBorderColor width: 1);
		aptitude: BrGlamorousRegularEditorAptitude;
		addShortcut: (BrEditorShortcut new
			name: 'Send message';
			combination: BlKeyCombination primaryReturn;
			performBlock: [ :editor | self sendMessage ];
			yourself)
]

{ #category : 'initialization' }
GtAcpShellElement >> initializeListElement [
	listElement := BrSimpleList vertical
		hMatchParent;
		vMatchParent;
		padding: (BlInsets all: 5);
		itemStencil: [ GtAcpMessageElement new ];
		itemDataBinder: [ :element :msg | 
			element session: session. 
			element client: client. 
			element message: msg ]
]

{ #category : 'initialization' }
GtAcpShellElement >> initializePermissionContainer [
	permissionContainer := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ];
		yourself
]

{ #category : 'initialization' }
GtAcpShellElement >> initializeStatusBar [
	statusLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new fontSize: 11; foreground: Color gray);
		text: 'Disconnected';
		hMatchParent;
		vFitContent.
	cancelButton := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude;
		label: 'Cancel';
		beSmallSize;
		visibility: BlVisibility gone;
		margin: (BlInsets left: 6);
		action: [ self cancelPrompt ].
	modeButton := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude;
		label: 'Mode';
		beSmallSize;
		visibility: BlVisibility gone;
		margin: (BlInsets left: 6);
		action: [ self cycleModes ].
	statusBar := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ];
		padding: (BlInsets top: 4 left: 8 bottom: 4 right: 8);
		addChild: statusLabel;
		addChild: modeButton;
		addChild: cancelButton;
		yourself
]

{ #category : 'event handling' }
GtAcpShellElement >> onPermissionRequested: anAnnouncement [
	self enqueueTask: (BlTaskAction new action: [
		self showPendingPermissions.
		"Also refresh messages so tool call elements show awaiting-permission state"
		lastMessageCount := nil.
		self updateMessages ])
]

{ #category : 'updating' }
GtAcpShellElement >> onSessionUpdated: anAnnouncement [
	self enqueueTask: (BlTaskAction new action: [
		| previousCount currentMode modeChanged |
		previousCount := lastMessageCount ifNil: [ -1 ].
		self updateMessages.
		currentMode := session
			ifNil: [ 'Mode' ]
			ifNotNil: [ session currentModeId ifNil: [ 'Mode' ] ].
		modeChanged := modeButton label asString ~= currentMode.
		(previousCount ~= lastMessageCount or: [ modeChanged ])
			ifTrue: [ self updateStatus ] ])
]

{ #category : 'actions' }
GtAcpShellElement >> sendMessage [
	| text |
	session ifNil: [ ^ self ].
	text := inputElement text asString trimBoth.
	text ifEmpty: [ ^ self ].
	inputElement text: '' asRopedText.
	cancelButton visibility: BlVisibility visible.
	client 
		prompt: text 
		inSession: session 
		do: [ :result |
			self enqueueTask: (BlTaskAction new action: [ 
				cancelButton visibility: BlVisibility gone.
				self updateMessages.
				self updateStatus ]) ]
		onError: [ :err |
			self enqueueTask: (BlTaskAction new action: [ 
				| errorText |
				cancelButton visibility: BlVisibility gone.
				errorText := err ifNil: [ 'Connection lost' ]
					ifNotNil: [
						(err isKindOf: Dictionary)
							ifTrue: [ (err at: 'error' ifAbsent: [ err ]) printString ]
							ifFalse: [ err printString ] ].
				statusLabel text: ('Error: ', errorText).
				self updateMessages ]) ]
]

{ #category : 'accessing' }
GtAcpShellElement >> session [
	^ session
]

{ #category : 'updating' }
GtAcpShellElement >> showPendingPermissions [
	"No-op: permissions are shown inline on tool call elements.
	 Previously this also added them to permissionContainer at the bottom, causing duplicates."
	permissionContainer removeChildren
]

{ #category : 'subscriptions' }
GtAcpShellElement >> subscribeToSession [
	session announcer
		when: GtAcpSessionUpdated
		send: #onSessionUpdated:
		to: self.
	session announcer
		when: GtAcpPermissionRequested
		send: #onPermissionRequested:
		to: self
]

{ #category : 'private' }
GtAcpShellElement >> updateMessages [
	| msgs messageCount |
	msgs := session messages.
	messageCount := msgs size.
	(lastMessageCount = messageCount) ifTrue: [ ^ self ].
	lastMessageCount := messageCount.
	listElement items: msgs.
	msgs ifNotEmpty: [ listElement scrollToItem: msgs last ]
]

{ #category : 'updating' }
GtAcpShellElement >> updateStatus [
	| text currentText modes bgTasks runningCount completedCount |
	text := session
		ifNil: [ 'Disconnected' ]
		ifNotNil: [
			String streamContents: [ :s |
				s nextPutAll: session cwd.
				s nextPutAll: ' | '.
				s nextPutAll: (session sessionId copyFrom: 1 to: 8).
				s nextPutAll: '...'.
				session messages ifNotEmpty: [
					s nextPutAll: ' | '.
					s print: session messages size.
					s nextPutAll: ' msgs' ].
				bgTasks := session backgroundTasks.
				bgTasks ifNotEmpty: [
					runningCount := (bgTasks count: [ :t | (t at: 'status' ifAbsent: [ 'running' ]) ~= 'completed' ]).
					completedCount := bgTasks size - runningCount.
					s nextPutAll: ' | bg: '.
					runningCount > 0 ifTrue: [
						s print: runningCount.
						s nextPutAll: ' running' ].
					(runningCount > 0 and: [ completedCount > 0 ]) ifTrue: [ s nextPutAll: ', ' ].
					completedCount > 0 ifTrue: [
						s print: completedCount.
						s nextPutAll: ' done' ] ] ] ].
	currentText := statusLabel text asString.
	currentText = text ifFalse: [ statusLabel text: text ].
	session ifNotNil: [
		modes := session availableModes.
		(modes notNil and: [ modes notEmpty ])
			ifTrue: [
				modeButton visibility: BlVisibility visible.
				modeButton label: (session currentModeId ifNil: [ 'Mode' ]) ]
			ifFalse: [ modeButton visibility: BlVisibility gone ] ]
]
