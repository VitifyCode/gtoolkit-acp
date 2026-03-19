Class {
	#name : 'GtAcpHomeSection',
	#superclass : 'GtHomeMultiCardSection',
	#category : 'GToolkit-ACP-UI',
	#package : 'GToolkit-ACP-UI'
}

{ #category : 'cards' }
GtAcpHomeSection >> acpShellCard [
	<gtSectionCard>
	| card |
	card := GtHomeCard explicit.
	^ card
		title: 'Claude Code';
		description: 'Browse and manage agent sessions';
		priority: 10;
		stencil: [
			| container titleLabel subtitleLabel nodePathElement jsPathElement inspectArea pathsArea |
			titleLabel := BrLabel new
				beLargeSize;
				padding: (BlInsets bottom: 5);
				aptitude: BrGlamorousLabelAptitude new bold;
				text: 'Claude Code'.
			subtitleLabel := BrLabel new
				aptitude: (BrGlamorousLabelAptitude new foreground: Color gray; fontSize: 12);
				text: 'Browse and manage agent sessions'.

			nodePathElement := GtAcpFilePathElement new
				hMatchParent;
				label: 'Node:';
				path: GtClaudeCodeClient programPath asFileReference;
				onPathChanged: [ :aPathString |
					GtClaudeCodeClient programPath: aPathString ].

			jsPathElement := GtAcpFilePathElement new
				hMatchParent;
				label: 'ACP JS:';
				path: GtClaudeCodeClient programArgs first asFileReference;
				onPathChanged: [ :aPathString |
					GtClaudeCodeClient programArgs: { aPathString } ].

			inspectArea := BrVerticalPane new
				hMatchParent;
				vFitContent;
				when: BlClickEvent do: [ :anEvent |
					anEvent consumed: true.
					inspectArea phlow spawnOrShowObject: GtAcpClientRegistry uniqueInstance ].
			inspectArea addChild: titleLabel preventMeAndChildrenMouseEvents.
			inspectArea addChild: subtitleLabel preventMeAndChildrenMouseEvents.

			pathsArea := BrVerticalPane new
				hMatchParent;
				vFitContent;
				cellSpacing: 4;
				padding: (BlInsets top: 10);
				when: BlClickEvent do: [ :e | e consumed: true ];
				when: BlDoubleClickEvent do: [ :e | e consumed: true ];
				addChild: nodePathElement;
				addChild: jsPathElement.

			container := BrVerticalPane new
				exact: 400 @ 170;
				background: Color white;
				aptitude: BrShadowAptitude new beLarge
					+ (BrGlamorousButtonExteriorAptitude new
						backgroundPaint: Color white;
						borderPaint: Color transparent);
				padding: (BlInsets all: 15);
				margin: (BlInsets
					top: self spaceGap
					left: 2 * self spaceGap
					bottom: 2 * self spaceGap
					right: 2 * self spaceGap).
			container addChild: inspectArea.
			container addChild: pathsArea.
			container ]
]

{ #category : 'private' }
GtAcpHomeSection >> allSessions [
	^ GtAcpClientRegistry uniqueInstance activeClients
		flatCollect: [ :c | c sessions values ]
]

{ #category : 'private' }
GtAcpHomeSection >> buildSessionElementFor: aSession [
	| element titleLabel cwdLabel |
	titleLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new bold);
		text: ('Session: ', (aSession sessionId copyFrom: 1 to: (8 min: aSession sessionId size))).
	cwdLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: Color gray; fontSize: 12);
		text: (aSession cwd ifNil: [ 'no cwd' ]).
	element := BrHorizontalPane new
		hMatchParent;
		vFitContent;
		padding: (BlInsets all: 8);
		alignCenterLeft;
		background: Color white;
		aptitude: (BrGlamorousButtonExteriorAptitude new
			backgroundPaint: Color white;
			borderPaint: BrGlamorousColors disabledButtonBorderColor);
		margin: (BlInsets top: 4 left: self spaceGap * 2 bottom: 4 right: self spaceGap * 2);
		when: BlClickEvent do: [ :anEvent |
			anEvent consumed: true.
			element phlow spawnObject: aSession ];
		addChild: (BrVerticalPane new
			hMatchParent;
			vFitContent;
			addChild: titleLabel;
			addChild: cwdLabel).
	^ element
]

{ #category : 'building' }
GtAcpHomeSection >> create [
	| sectionContainer cardsContainer sessionsContainer homeSection |
	homeSection := self.
	sectionContainer := self newSectionContainer.
	sectionContainer addChild: (self newSectionTitle: self sectionTitle).
	cardsContainer := self newCardsContainer.
	self cards do: [ :card | cardsContainer addChild: card asElement ].
	sectionContainer addChild: cardsContainer.
	sessionsContainer := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c |
			c horizontal matchParent.
			c vertical fitContent ].
	homeSection refreshSessionsContainer: sessionsContainer.
	sectionContainer addChild: sessionsContainer.
	sectionContainer
		when: BlElementAddedToSceneGraphEvent
		do: [ :e |
			GtAcpClientRegistry uniqueInstance announcer
				when: GtAcpClientRegistryUpdated
				do: [ :ann |
					sessionsContainer enqueueTask: (BlTaskAction new action: [
						homeSection refreshSessionsContainer: sessionsContainer ]) ]
				for: sessionsContainer ].
	sectionContainer
		when: BlElementRemovedFromSceneGraphEvent
		do: [ :e |
			GtAcpClientRegistry uniqueInstance announcer
				unsubscribe: sessionsContainer ].
	^ sectionContainer
]

{ #category : 'private' }
GtAcpHomeSection >> refreshSessionsContainer: sessionsContainer [
	sessionsContainer removeChildren.
	self allSessions do: [ :session |
		sessionsContainer addChild: (self buildSessionElementFor: session) ]
]

{ #category : 'accessing' }
GtAcpHomeSection >> sectionTitle [
	^ 'Agents'
]
