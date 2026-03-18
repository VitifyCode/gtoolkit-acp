Class {
	#name : 'GtAcpToolCallElement',
	#superclass : 'BlElement',
	#instVars : [
		'toolCall',
		'headerElement',
		'statusIcon',
		'titleLabel',
		'errorLabel',
		'expandArrow',
		'detailContainer',
		'isExpanded',
		'session',
		'client',
		'permissionButtonsContainer'
	],
	#category : 'GToolkit-ACP-UI',
	#package : 'GToolkit-ACP-UI'
}

{ #category : 'private' }
GtAcpToolCallElement >> buildDetailContent [
	"Build expanded detail view showing input params and output, similar to Claude Code CLI format"
	detailContainer removeChildren.
	
	"Input parameters"
	(toolCall rawInput notNil and: [ toolCall rawInput notEmpty ]) ifTrue: [
		toolCall rawInput keysAndValuesDo: [ :key :value |
			| valueText |
			valueText := value asString.
			valueText size > 300 ifTrue: [ valueText := (valueText first: 300), '...' ].
			detailContainer addChild: (BrLabel new
				aptitude: (BrGlamorousLabelAptitude new fontSize: 11; foreground: Color darkGray);
				hMatchParent; vFitContent;
				text: (key asString, ': ', valueText)) ] ].
	
	"Output / response"
	toolCall rawOutput ifNotNil: [ :output |
		| outputText |
		outputText := output asString.
		outputText size > 500 ifTrue: [ outputText := (outputText first: 500), '...' ].
		detailContainer addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new fontSize: 10; foreground: Color gray);
			text: '---').
		detailContainer addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new fontSize: 11; 
				foreground: (toolCall status = 'failed' 
					ifTrue: [ Color red darker ] 
					ifFalse: [ Color darkGray ]));
			hMatchParent; vFitContent;
			text: outputText) ].
	
	"Click to inspect in detail"
	detailContainer addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new fontSize: 10; foreground: (Color blue alpha: 0.7));
		text: 'click to inspect';
		margin: (BlInsets top: 2);
		when: BlClickEvent do: [ :e |
			e consumed: true.
			self phlow spawnOrShowObject: toolCall ])
]

{ #category : 'accessing' }
GtAcpToolCallElement >> client: aClient [
	client := aClient
]

{ #category : 'initialization' }
GtAcpToolCallElement >> initialize [
	super initialize.
	isExpanded := false.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	self padding: (BlInsets top: 2 bottom: 2 left: 8 right: 8).
	self margin: (BlInsets top: 2 bottom: 2).
	self background: (Color veryLightGray alpha: 0.2).
	self border: (BlBorder paint: (Color gray alpha: 0.3) width: 1).
	
	"Header row: status icon + title + expand arrow"
	headerElement := BrHorizontalPane new
		hMatchParent;
		vFitContent;
		alignCenterLeft.
	headerElement when: BlClickEvent do: [ :e |
		e consumed: true.
		self toggleExpanded ].
	statusIcon := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new fontSize: 12);
		text: '...';
		margin: (BlInsets right: 6).
	titleLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new fontSize: 11; foreground: Color darkGray);
		hMatchParent;
		vFitContent.
	expandArrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new fontSize: 10; foreground: Color gray);
		text: '>';
		margin: (BlInsets left: 6).
	headerElement addChild: statusIcon.
	headerElement addChild: titleLabel.
	headerElement addChild: expandArrow.
	
	"Permission buttons container (hidden by default)"
	permissionButtonsContainer := BrHorizontalPane new
		hMatchParent;
		vFitContent;
		padding: (BlInsets top: 6 left: 18);
		visibility: BlVisibility gone.
	
	"Detail container (hidden by default)"
	detailContainer := BrVerticalPane new
		hMatchParent;
		vFitContent;
		padding: (BlInsets top: 4 left: 18);
		visibility: BlVisibility gone.
	
	"Error label (hidden by default)"
	errorLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new fontSize: 11; foreground: (Color red darker));
		hMatchParent;
		vFitContent;
		padding: (BlInsets top: 2 left: 18);
		visibility: BlVisibility gone.
	
	self addChild: headerElement.
	self addChild: permissionButtonsContainer.
	self addChild: errorLabel.
	self addChild: detailContainer
]

{ #category : 'accessing' }
GtAcpToolCallElement >> session: aSession [
	session := aSession
]

{ #category : 'updating' }
GtAcpToolCallElement >> showPermissionButtons: aPermissionRequest [
	| options requestId |
	permissionButtonsContainer removeChildren.
	options := aPermissionRequest at: 'options' ifAbsent: [ #() ].
	requestId := aPermissionRequest at: 'requestId'.
	options do: [ :opt |
		| button optionId |
		optionId := opt at: 'optionId' ifAbsent: [ '?' ].
		button := BrButton new
			aptitude: BrGlamorousButtonWithLabelAptitude;
			label: (opt at: 'name' ifAbsent: [ '?' ]);
			margin: (BlInsets right: 8);
			action: [ 
				client ifNotNil: [
					aPermissionRequest at: 'status' put: optionId.
					client allowPermissionRequest: requestId optionId: optionId.
					"Track always-allowed tools"
					((opt at: 'kind' ifAbsent: [ '' ]) = 'allow_always') ifTrue: [
						session alwaysAllowedTools add: toolCall title ].
					permissionButtonsContainer removeChildren.
					permissionButtonsContainer visibility: BlVisibility gone.
					self update ] ].
		permissionButtonsContainer addChild: button ].
	permissionButtonsContainer visibility: BlVisibility visible
]

{ #category : 'actions' }
GtAcpToolCallElement >> toggleExpanded [
	isExpanded := isExpanded not.
	isExpanded
		ifTrue: [
			expandArrow text: 'v'.
			self buildDetailContent.
			detailContainer visibility: BlVisibility visible ]
		ifFalse: [
			expandArrow text: '>'.
			detailContainer removeChildren.
			detailContainer visibility: BlVisibility gone ]
]

{ #category : 'accessing' }
GtAcpToolCallElement >> toolCall [
	^ toolCall
]

{ #category : 'accessing' }
GtAcpToolCallElement >> toolCall: aGtAcpToolCall [
	toolCall := aGtAcpToolCall.
	self update
]

{ #category : 'updating' }
GtAcpToolCallElement >> update [
	| titleText icon isAwaitingPermission permissionRequest |
	titleText := toolCall title ifNil: [ 'Tool call' ].
	toolCall inputSummary ifNotNil: [ :s | titleText := titleText, ' - ', s ].
	titleLabel text: titleText.
	
	"Check if this tool call is awaiting permission approval"
	isAwaitingPermission := false.
	permissionRequest := nil.
	session ifNotNil: [
		permissionRequest := session pendingPermissionForToolTitle: toolCall title.
		isAwaitingPermission := permissionRequest notNil ].
	
	isAwaitingPermission ifTrue: [
		icon := '?'.
		statusIcon aptitude foreground: (Color r: 0.7 g: 0.4 b: 0.0).
		titleLabel aptitude foreground: (Color r: 0.6 g: 0.3 b: 0.0).
		self background: (Color r: 1.0 g: 0.95 b: 0.8).
		self border: (BlBorder paint: (Color r: 0.9 g: 0.7 b: 0.2) width: 2).
		errorLabel visibility: BlVisibility gone.
		self showPermissionButtons: permissionRequest.
		statusIcon text: icon.
		isExpanded ifTrue: [ self buildDetailContent ].
		^ self ].
	
	"Hide permission buttons when not awaiting"
	permissionButtonsContainer removeChildren.
	permissionButtonsContainer visibility: BlVisibility gone.
	
	toolCall status = 'completed' ifTrue: [
		icon := '+'.
		statusIcon aptitude foreground: Color gray.
		self background: (Color veryLightGray alpha: 0.2).
		self border: (BlBorder paint: (Color gray alpha: 0.3) width: 1).
		errorLabel visibility: BlVisibility gone ].
	toolCall status = 'failed' ifTrue: [
		| errorText |
		icon := 'x'.
		statusIcon aptitude foreground: Color red.
		self background: (Color red alpha: 0.05).
		self border: (BlBorder paint: (Color red alpha: 0.3) width: 1).
		errorText := toolCall rawOutput ifNil: [ '' ].
		errorText isEmpty ifFalse: [
			errorLabel text: (errorText asString truncateTo: 200).
			errorLabel visibility: BlVisibility visible ] ].
	(toolCall status = 'pending' or: [ toolCall status = 'in_progress' or: [ toolCall status isNil ] ]) ifTrue: [
		icon := '...'.
		statusIcon aptitude foreground: Color gray.
		self background: (Color veryLightGray alpha: 0.2).
		self border: (BlBorder paint: (Color gray alpha: 0.3) width: 1).
		errorLabel visibility: BlVisibility gone ].
		
	statusIcon text: icon.
		
	"Refresh detail content if expanded"
	isExpanded ifTrue: [ self buildDetailContent ]
]
