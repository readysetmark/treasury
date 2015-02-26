Treasury
========

** TODO: Add description **


To dos:

[ ] Create data types for journal
[ ] Update type specs in parser
		[x] Date
		[ ] EntryHeader
			- Get rid of {:ok, blah} in optional fields
		[ ] Run dialyzer
[ ] Update quantity parser
		- Am I going to use a decimal library or roll my own "money" type?
		- Don't like returning {:ok, _} for fraction part
[ ] Roll comment block for Amount parsers into the @doc
