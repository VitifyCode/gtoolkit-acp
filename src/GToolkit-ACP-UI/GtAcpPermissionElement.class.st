Class {
	#name : 'GtAcpPermissionElement',
	#superclass : 'BlElement',
	#instVars : [
		'request',
		'client',
		'session',
		'titleElement',
		'optionsContainer'
	],
	#category : 'GToolkit-ACP-UI',
	#package : 'GToolkit-ACP-UI'
}

{ #category : 'initialization' }
GtAcpPermissionElement >> initialize [
	super initialize.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	self padding: (BlInsets all: 12).
	self margin: (BlInsets top: 6 bottom: 6).
	self background: (Color r: 1.0 g: 0.95 b: 0.8).
	self border: (BlBorder paint: (Color r: 0.9 g: 0.7 b: 0.2) width: 2).
	self initializeTitleElement.
	self initializeOptionsContainer.
	self addChild: titleElement as: #title.
	self addChild: optionsContainer as: #options
]

{ #category : 'initialization' }
GtAcpPermissionElement >> initializeOptionsContainer [
	optionsContainer := BlElement new
		layout: BlLinearLayout horizontal;
		constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ];
		yourself
]

{ #category : 'initialization' }
GtAcpPermissionElement >> initializeTitleElement [
	titleElement := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new bold; fontSize: 13; foreground: (Color r: 0.6 g: 0.3 b: 0.0));
		text: 'Action required';
		hMatchParent;
		vFitContent;
		margin: (BlInsets bottom: 8)
]

{ #category : 'accessing' }
GtAcpPermissionElement >> request: aRequest client: aClient [
	| toolCall title options |
	request := aRequest.
	client := aClient.
	toolCall := request at: 'toolCall' ifAbsent: [ Dictionary new ].
	title := toolCall at: 'title' ifAbsent: [ 'Unknown tool' ].
	titleElement text: ('Permission: ' , title).
	options := request at: 'options' ifAbsent: [ #() ].
	optionsContainer removeChildren.
	options do: [ :opt |
		| button |
		button := BrButton new
			aptitude: BrGlamorousButtonWithLabelAptitude;
			label: (opt at: 'name' ifAbsent: [ '?' ]);
			margin: (BlInsets right: 6);
			action: [ self respondWith: (opt at: 'optionId') ].
		(opt at: 'kind' ifAbsent: [ '' ]) = 'reject_once' ifTrue: [
			button aptitude: BrGlamorousButtonWithLabelAptitude ].
		optionsContainer addChild: button ]
]

{ #category : 'initialization' }
GtAcpPermissionElement >> request: aRequest client: aClient session: aSession [
	| toolCall title options inputSummary |
	request := aRequest.
	client := aClient.
	session := aSession.
	toolCall := request at: 'toolCall' ifAbsent: [ Dictionary new ].
	title := toolCall at: 'title' ifAbsent: [ 'Unknown tool' ].
	titleElement text: ('Action required: ' , title).
	"Add input summary if available"
	inputSummary := (toolCall at: 'rawInput' ifAbsent: [ nil ]).
	(inputSummary notNil and: [ inputSummary notEmpty ]) ifTrue: [
		| summaryText summaryLabel |
		summaryText := ', ' join: (inputSummary associations collect: [ :assoc |
			assoc key asString, ': ', (assoc value printString truncateTo: 80) ]).
		summaryLabel := BrLabel new
			aptitude: (BrGlamorousLabelAptitude new fontSize: 11; foreground: Color darkGray);
			text: summaryText;
			hMatchParent;
			vFitContent;
			margin: (BlInsets bottom: 8).
		self addChild: summaryLabel after: titleElement ].
	options := request at: 'options' ifAbsent: [ #() ].
	optionsContainer removeChildren.
	options do: [ :opt |
		| button |
		button := BrButton new
			aptitude: BrGlamorousButtonWithLabelAptitude;
			label: (opt at: 'name' ifAbsent: [ '?' ]);
			margin: (BlInsets right: 8);
			action: [ self respondWith: (opt at: 'optionId') ].
		optionsContainer addChild: button ]
]

{ #category : 'actions' }
GtAcpPermissionElement >> respondWith: anOptionId [
	| requestId toolTitle option |
	requestId := request at: 'requestId'.
	request at: 'status' put: anOptionId.
	client allowPermissionRequest: requestId optionId: anOptionId.
	"Track always-allowed tools on the session"
	option := (request at: 'options' ifAbsent: [ #() ]) 
		detect: [ :o | (o at: 'optionId') = anOptionId ] ifNone: [ nil ].
	(option notNil and: [ (option at: 'kind' ifAbsent: [ '' ]) = 'allow_always' ]) ifTrue: [
		toolTitle := (request at: 'toolCall' ifAbsent: [ Dictionary new ]) at: 'title' ifAbsent: [ nil ].
		toolTitle ifNotNil: [ session alwaysAllowedTools add: toolTitle ] ].
	self removeFromParent
]
