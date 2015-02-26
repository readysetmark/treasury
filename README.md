Treasury
========

** TODO: Add description **


To dos:

[ ] Create data types for journal
[ ] Update type specs in parser
		[x] Date
		[x] EntryHeader
		[ ] Amount
		...?
		[ ] Run dialyzer
[ ] Update quantity parser
		- Am I going to use a decimal library or roll my own "money" type?
		- Don't like returning {:ok, _} for fraction part
[ ] Roll comment block for Amount parsers into the @doc
