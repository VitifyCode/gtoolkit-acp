Class {
	#name : 'GtAcpMarkdownStyler',
	#superclass : 'GtLMessageStyler',
	#category : 'GToolkit-ACP-UI',
	#package : 'GToolkit-ACP-UI'
}

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> buildTableElementFor: aTableString [
	"Build a full-featured table element from a markdown table string.
	 Supports: column alignment, inline styling, zebra striping, styled headers."
	| lines separatorLine headerLine dataLines headers rows alignments list container |
	lines := aTableString lines.
	headerLine := lines first.
	separatorLine := lines second.
	dataLines := lines allButFirst allButFirst reject: [ :l | self isSeparatorLine: l ].
	headers := self parseCellsFrom: headerLine.
	rows := dataLines collect: [ :row | self parseCellsFrom: row ].
	alignments := self parseAlignmentsFrom: separatorLine.
	
	"Pad alignments if fewer than headers"
	[ alignments size < headers size ] whileTrue: [
		alignments := alignments copyWith: #left ].
	
	list := BrColumnedList new.
	list items: rows.
	list addAptitude: (BrColumnedListHeaderAptitude new
		labelStencil: [ :aColumn |
			| headerCell headerText colIndex alignment textElement |
			colIndex := headers indexOf: aColumn title.
			alignment := (colIndex > 0 and: [ colIndex <= alignments size ])
				ifTrue: [ alignments at: colIndex ]
				ifFalse: [ #left ].
			
			headerText := aColumn title asRopedText.
			headerText bold.
			headerText glamorousRegularFont.
			headerText fontSize: 13.
			
			headerCell := BlElement new.
			headerCell layout: BlFrameLayout new.
			headerCell padding: (BlInsets top: 6 left: 8 bottom: 6 right: 8).
			headerCell background: BrGlamorousColors defaultHeaderBackgroundColor.
			
			textElement := BlAttributedTextElement new.
			textElement text: headerText.
			textElement constraintsDo: [ :c |
				c horizontal fitContent.
				c vertical fitContent.
				alignment = #center ifTrue: [ c frame horizontal alignCenter ].
				alignment = #right ifTrue: [ c frame horizontal alignRight ] ].
			
			headerCell addChild: textElement.
			aColumn columnWidth applyOn: headerCell.
			headerCell ]).
	
	headers withIndexDo: [ :h :i |
		| alignment |
		alignment := (i <= alignments size) ifTrue: [ alignments at: i ] ifFalse: [ #left ].
		list column
			title: h;
			weight: 1;
			cellStencil: [ self newCellElement: alignment ];
			dataBinder: [ :cell :row :rowIndex |
				| cellValue styledText textElement |
				cellValue := (i <= row size) ifTrue: [ row at: i ] ifFalse: [ '' ].
				styledText := self styleRopedText: cellValue.
				textElement := cell children first.
				textElement text: styledText.
				
				"Zebra striping on the row element"
				cell parent ifNotNil: [ :rowElement |
					rowElement background: (rowIndex even
						ifTrue: [ BrGlamorousColors neutralBackgroundColor ]
						ifFalse: [ Color transparent ]) ] ] ].
	
	list hMatchParent.
	list vExact: ((rows size + 1) * 30 min: 500).
	
	"Wrap in a container"
	container := BlElement new.
	container layout: BlLinearLayout vertical.
	container constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContentLimited ].
	container padding: (BlInsets top: 4 bottom: 4).
	container addChild: list.
	^ container
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> findTableRegionsIn: aString [
	"Find markdown table regions in the text. Returns a collection of 
	 intervals (start->stop character positions) for each table found."
	| lines lineStarts regions tableStartLine i |
	lines := aString lines.
	lines ifEmpty: [ ^ #() ].
	
	"Build line start positions"
	lineStarts := OrderedCollection new: lines size.
	lineStarts add: 1.
	aString doWithIndex: [ :c :idx |
		c = Character lf ifTrue: [ lineStarts add: idx + 1 ] ].
	
	regions := OrderedCollection new.
	tableStartLine := nil.
	i := 1.
	[ i <= lines size ] whileTrue: [
		| line |
		line := lines at: i.
		(line trimBoth beginsWith: '|')
			ifTrue: [ tableStartLine ifNil: [ tableStartLine := i ] ]
			ifFalse: [
				tableStartLine ifNotNil: [
					(self isValidTableFrom: tableStartLine to: i - 1 in: lines)
						ifTrue: [ | startChar endChar |
							startChar := lineStarts at: tableStartLine.
							endChar := (i <= lineStarts size
								ifTrue: [ (lineStarts at: i) - 2 ]
								ifFalse: [ aString size ]).
							regions add: (startChar to: endChar) ].
					tableStartLine := nil ] ].
		i := i + 1 ].
	tableStartLine ifNotNil: [
		(self isValidTableFrom: tableStartLine to: lines size in: lines)
			ifTrue: [ | startChar endChar |
				startChar := lineStarts at: tableStartLine.
				endChar := aString size.
				regions add: (startChar to: endChar) ] ].
	^ regions
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> isSeparatorLine: aLine [
	"Check if a line is a table separator (only dashes, pipes, colons, spaces)."
	^ aLine trimBoth allSatisfy: [ :c | '|-: ' includes: c ]
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> isValidTableFrom: startLine to: endLine in: lines [
	"A valid markdown table needs at least 2 lines (header + separator),
	 and the second line must be a separator (all dashes, pipes, colons, spaces)."
	| count separatorLine |
	count := endLine - startLine + 1.
	count < 2 ifTrue: [ ^ false ].
	separatorLine := (lines at: startLine + 1) trimBoth.
	^ separatorLine allSatisfy: [ :c | '|-: ' includes: c ]
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> newCellElement: alignment [
	"Create a cell element with the given alignment (#left, #center, #right).
	 Uses a BlElement container with frame layout for proper alignment."
	| container textElement |
	container := BlElement new.
	container layout: BlFrameLayout new.
	container constraintsDo: [ :c |
		c horizontal matchParent.
		c vertical fitContent ].
	container padding: (BlInsets top: 4 left: 8 bottom: 4 right: 8).
	
	textElement := BlAttributedTextElement new.
	textElement constraintsDo: [ :c |
		c horizontal fitContent.
		c vertical fitContent.
		alignment = #center ifTrue: [ c frame horizontal alignCenter ].
		alignment = #right ifTrue: [ c frame horizontal alignRight ] ].
	textElement userData at: #isTextElement put: true.
	
	container addChild: textElement.
	^ container
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> parseAlignmentsFrom: aSeparatorLine [
	"Parse column alignments from a markdown separator line.
	 :--- = left, :---: = center, ---: = right, --- = left (default).
	 Returns an array of symbols: #left, #center, or #right."
	| cells |
	cells := (aSeparatorLine splitOn: '|')
		select: [ :s | s trimBoth isNotEmpty ]
		thenCollect: [ :s | s trimBoth ].
	^ cells collect: [ :cell |
		| leftColon rightColon |
		leftColon := cell beginsWith: ':'.
		rightColon := cell endsWith: ':'.
		(leftColon and: [ rightColon ])
			ifTrue: [ #center ]
			ifFalse: [ rightColon
				ifTrue: [ #right ]
				ifFalse: [ #left ] ] ]
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> parseCellsFrom: aLine [
	"Split a pipe-delimited line into cell values."
	^ (aLine splitOn: '|')
		select: [ :s | s trimBoth isNotEmpty ]
		thenCollect: [ :s | s trimBoth ]
]

{ #category : 'styling' }
GtAcpMarkdownStyler >> privateStyle: aText [
	"Style text with markdown, including table support.
	 Tables are detected first and replaced with BrColumnedList elements,
	 then the rest is styled by the parent (headers, bold, code, etc.)."
	| tableRegions textString |
	textString := aText asString.
	tableRegions := self findTableRegionsIn: textString.
	
	tableRegions do: [ :region |
		| tableString firstLineEnd |
		tableString := textString copyFrom: region first to: region last.
		
		"Find the end of the first line"
		firstLineEnd := textString indexOf: Character lf startingAt: region first ifAbsent: [ region last + 1 ].
		firstLineEnd := firstLineEnd min: (region last + 1).
		firstLineEnd := firstLineEnd - 1. "Exclude the newline itself"
		
		"Replace the first line content with the table element"
		(aText from: region first to: firstLineEnd)
			attribute: (BrTextAdornmentDynamicAttribute new
				beReplace;
				stencil: [ :aTBrTextEditorTextualPiece :anEditorElement |
					{ self buildTableElementFor: tableString } ]).
		
		"Hide all remaining characters after the first line"
		(firstLineEnd + 1 <= region last) ifTrue: [
			(aText from: firstLineEnd + 1 to: region last)
				attributes: {
					BlFontSizeAttribute new size: 0.
					BlTextForegroundAttribute paint: Color transparent } ] ].
	
	^ super privateStyle: aText
]

{ #category : 'styling' }
GtAcpMarkdownStyler >> styleAutoHiding: leftRange and: rightRange whenOutside: nodeInterval [
	"In read-only chat context, always hide markdown syntax markers"
	| anAttribute |
	anAttribute := BrTextAdornmentDynamicAttribute new
		beReplace;
		stencil: [ :aTBrTextEditorTextualPiece :anEditorElement | #() ].
	self text
		attributes: { anAttribute }
		from: leftRange first
		to: leftRange last.
	self text
		attributes: { anAttribute copy }
		from: rightRange first
		to: rightRange last
]

{ #category : 'styling' }
GtAcpMarkdownStyler >> styleAutoHiding: anInterval text: aSubText [
	"In read-only chat context, always hide markdown syntax markers"
	| anAttribute |
	anAttribute := BrTextAdornmentDynamicAttribute new
		beReplace;
		stencil: [ :aTBrTextEditorTextualPiece :anEditorElement | #() ].
	aSubText attribute: anAttribute
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> styleRopedText: aString [
	"Parse inline markdown from aString, strip syntax markers,
	 and return a styled BlRopedText suitable for BrLabel.
	 Handles: **bold**, *italic*, `code`, ~~strikethrough~~.
	 Builds the plain text first, collects style ranges, then applies."
	| plainText styleRanges pos len src result |
	plainText := String new writeStream.
	styleRanges := OrderedCollection new.
	pos := 1.
	src := aString.
	len := src size.
	
	[ pos <= len ] whileTrue: [
		| ch |
		ch := src at: pos.
		
		"~~strikethrough~~"
		(ch = $~ and: [ pos + 1 <= len and: [ (src at: pos + 1) = $~ ] ])
			ifTrue: [
				| endPos j startIdx |
				j := pos + 2.
				endPos := 0.
				[ j <= (len - 1) and: [ endPos = 0 ] ] whileTrue: [
					((src at: j) = $~ and: [ (src at: j + 1) = $~ ])
						ifTrue: [ endPos := j ].
					j := j + 1 ].
				endPos > 0
					ifTrue: [
						startIdx := plainText position + 1.
						plainText nextPutAll: (src copyFrom: pos + 2 to: endPos - 1).
						styleRanges add: { startIdx. plainText position. #strikethrough }.
						pos := endPos + 2 ]
					ifFalse: [
						plainText nextPut: ch.
						pos := pos + 1 ] ]
		
		"**bold**"
		ifFalse: [ (ch = $* and: [ pos + 1 <= len and: [ (src at: pos + 1) = $* ] ])
			ifTrue: [
				| endPos j startIdx |
				j := pos + 2.
				endPos := 0.
				[ j <= (len - 1) and: [ endPos = 0 ] ] whileTrue: [
					((src at: j) = $* and: [ (src at: j + 1) = $* ])
						ifTrue: [ endPos := j ].
					j := j + 1 ].
				endPos > 0
					ifTrue: [
						startIdx := plainText position + 1.
						plainText nextPutAll: (src copyFrom: pos + 2 to: endPos - 1).
						styleRanges add: { startIdx. plainText position. #bold }.
						pos := endPos + 2 ]
					ifFalse: [
						plainText nextPut: ch.
						pos := pos + 1 ] ]
		
		"`code`"
		ifFalse: [ ch = $`
			ifTrue: [
				| endPos startIdx |
				endPos := src indexOf: $` startingAt: pos + 1 ifAbsent: [ 0 ].
				endPos > 0
					ifTrue: [
						startIdx := plainText position + 1.
						plainText nextPutAll: (src copyFrom: pos + 1 to: endPos - 1).
						styleRanges add: { startIdx. plainText position. #code }.
						pos := endPos + 1 ]
					ifFalse: [
						plainText nextPut: ch.
						pos := pos + 1 ] ]
		
		"*italic*"
		ifFalse: [ (ch = $* and: [ pos + 1 <= len and: [ (src at: pos + 1) ~= $* ] ])
			ifTrue: [
				| endPos startIdx |
				endPos := src indexOf: $* startingAt: pos + 1 ifAbsent: [ 0 ].
				endPos > 0
					ifTrue: [
						startIdx := plainText position + 1.
						plainText nextPutAll: (src copyFrom: pos + 1 to: endPos - 1).
						styleRanges add: { startIdx. plainText position. #italic }.
						pos := endPos + 1 ]
					ifFalse: [
						plainText nextPut: ch.
						pos := pos + 1 ] ]
		
		"Regular character"
		ifFalse: [
			plainText nextPut: ch.
			pos := pos + 1 ] ] ] ] ].
	
	result := plainText contents asRopedText.
	result glamorousRegularFont.
	result fontSize: 13.
	
	styleRanges do: [ :range |
		| start end style sub |
		start := range first.
		end := range second.
		style := range third.
		(start <= end and: [ end <= result size ]) ifTrue: [
			sub := result from: start to: end.
			style = #bold ifTrue: [
				sub bold ].
			style = #italic ifTrue: [
				sub italic ].
			style = #code ifTrue: [
				sub glamorousCodeFont.
				sub attribute: (BlTextHighlightAttribute paint: BrGlamorousColors neutralBackgroundColor) ].
			style = #strikethrough ifTrue: [
				| decoration |
				decoration := BlTextDecoration new.
				decoration withLineThrough.
				decoration color: Color gray.
				decoration thickness: 2.
				sub foreground: Color gray.
				sub attribute: (BlTextDecorationAttribute new decoration: decoration) ] ] ].
	
	^ result
]

{ #category : 'private - tables' }
GtAcpMarkdownStyler >> styleStrikethrough: aRopedText source: aString [
	"Apply ~~strikethrough~~ styling. LeParser doesn't support this,
	 so we handle it with regex-like scanning."
	| i len |
	i := 1.
	len := aString size.
	[ i <= (len - 3) ] whileTrue: [
		((aString at: i) = $~ and: [ (aString at: i + 1) = $~ ]) ifTrue: [
			| endPos j |
			j := i + 2.
			endPos := nil.
			[ j <= (len - 1) and: [ endPos isNil ] ] whileTrue: [
				((aString at: j) = $~ and: [ (aString at: j + 1) = $~ ])
					ifTrue: [ endPos := j + 1 ].
				j := j + 1 ].
			endPos ifNotNil: [
				"Style the inner text with line-through"
				(aRopedText from: i + 2 to: endPos - 2)
					attribute: (BlTextDecorationAttribute new lineThrough;
						color: Color gray).
				"Hide ~~ markers"
				(aRopedText from: i to: i + 1)
					attribute: (BrTextAdornmentDynamicAttribute new beReplace;
						stencil: [ :p :e | #() ]).
				(aRopedText from: endPos - 1 to: endPos)
					attribute: (BrTextAdornmentDynamicAttribute new beReplace;
						stencil: [ :p :e | #() ]).
				i := endPos + 1 ]
			ifNil: [ i := i + 1 ] ]
		ifFalse: [ i := i + 1 ] ]
]
