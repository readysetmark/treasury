defmodule JournalParserTest do
	use ExUnit.Case, async: true
	alias Decimal, as: D
	alias JournalParser, as: P
	alias Types.Amount
	alias Types.Date
	alias Types.Posting
	alias Types.Symbol


	# Line Ending Parsers

	test "Line ending: Unix-style" do
		{:ok, _, result} = ExParsec.parse_text "\n", P.line_ending
		assert result == :newline
	end

	test "Line ending: Windows-style" do
		{:ok, _, result} = ExParsec.parse_text "\r\n", P.line_ending
		assert result == :newline
	end


	# Whitespace Parsers Tests

	test "Whitespace just spaces" do
		{:ok, _, result} = ExParsec.parse_text "   ", P.whitespace
		assert result == :whitespace
	end

	test "Whitespace just tabs" do
		{:ok, _, result} = ExParsec.parse_text "\t\t\t", P.whitespace
		assert result == :whitespace
	end

	test "Whitespace tabs and spaces" do
		{:ok, _, result} = ExParsec.parse_text " \t\t  ", P.whitespace
		assert result == :whitespace
	end

	test "Whitespace nothing" do
		{:ok, _, result} = ExParsec.parse_text "", P.whitespace
		assert result == :no_whitespace
	end

	test "Mandatory whitespace" do
		{:ok, _, result} = ExParsec.parse_text " ", P.mandatory_whitespace
		assert result == :whitespace
	end

	test "Mandatory whitespace missing" do
		{result, _} = ExParsec.parse_text "", P.mandatory_whitespace
		assert result == :error
	end


	# Line Number Parser Tests

	test "First line is 1" do
		{:ok, _, line_num} = ExParsec.parse_text "One Line", P.line_number
		assert line_num == 1
	end

	
	# Date Parser Tests

	test "Parse 4-digit year" do
		{:ok, _, year} = ExParsec.parse_text "2015", P.year
		assert year == 2015
	end

	test "Parse 2-digit month" do
		{:ok, _, month} = ExParsec.parse_text "02", P.month
		assert month == 2
	end

	test "Parse 2-digit day" do
		{:ok, _, day} = ExParsec.parse_text "14", P.day
		assert day == 14
	end

	test "Parse date with slashes" do
		{:ok, _, date} = ExParsec.parse_text "2015/02/14", P.date
		assert date.year == 2015
		assert date.month == 2
		assert date.day == 14
	end

	test "Parse date with dashes" do
		{:ok, _, date} = ExParsec.parse_text "2015-02-14", P.date
		assert date.year == 2015
		assert date.month == 2
		assert date.day == 14
	end


	# Transaction Status Parser Tests

	test "* denotes cleared transaction" do
		{:ok, _, status} = ExParsec.parse_text "*", P.transaction_status
		assert status == :cleared
	end

	test "! denotes uncleared transaction" do
		{:ok, _, status} = ExParsec.parse_text "!", P.transaction_status
		assert status == :uncleared
	end


	# Code Parser Tests

	test "Long transaction code" do
		{:ok, _, code} = ExParsec.parse_text "(conf# ABC-123-def)", P.code
		assert code == "conf# ABC-123-def"
	end

	test "Short transaction code" do
		{:ok, _, code} = ExParsec.parse_text "(89)", P.code
		assert code == "89"
	end

	test "Empty code" do
		{:ok, _, code} = ExParsec.parse_text "()", P.code
		assert code == ""
	end


	# Payee Parser Tests

	test "Long payee" do
		{:ok, _, payee} = 
			ExParsec.parse_text "WonderMart - groceries, toiletries, kitchen supplies",
													P.payee
		assert payee == "WonderMart - groceries, toiletries, kitchen supplies"
	end

	test "Short payee" do
		{:ok, _, payee} = ExParsec.parse_text "WonderMart", P.payee
		assert payee == "WonderMart"
	end

	test "Single character payee" do
		{:ok, _, payee} = ExParsec.parse_text "Z", P.payee
		assert payee == "Z"
	end

	test "Payee must have at least one character" do
		{result, _} = ExParsec.parse_text "", P.payee
		assert result == :error
	end


	# Comment Parser Tests

	test "Comment with leading space" do
		{:ok, _, comment} = ExParsec.parse_text "; Comment", P.comment
		assert comment == " Comment"
	end

	test "Comment with no leading space" do
		{:ok, _, comment} = ExParsec.parse_text ";Comment", P.comment
		assert comment == "Comment"
	end

	test "Empty comment" do
		{:ok, _, comment} = ExParsec.parse_text ";", P.comment
		assert comment == ""
	end


	# Transaction Header Parser Tests

	test "Full transaction header" do
		{:ok, _, header} = 
			ExParsec.parse_text "2015/02/15 * (conf# abc-123) Payee ;Comment", 
													P.header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :cleared
		assert header.code == "conf# abc-123"
		assert header.payee == "Payee "
		assert header.comment == "Comment"
	end

	test "Transaction header with code and no comment" do
		{:ok, _, header} =
			ExParsec.parse_text "2015/02/15 ! (conf# abc-123) Payee", P.header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :uncleared
		assert header.code == "conf# abc-123"
		assert header.payee == "Payee"
		assert header.comment == nil
	end

	test "Transaction header with comment and no code" do
		{:ok, _, header} =
			ExParsec.parse_text "2015/02/15 * Payee ;Comment", P.header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :cleared
		assert header.code == nil
		assert header.payee == "Payee "
		assert header.comment == "Comment"
	end

	test "Transaction header with no code or comment" do
		{:ok, _, header} =
			ExParsec.parse_text "2015/02/15 * Payee", P.header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :cleared
		assert header.code == nil
		assert header.payee == "Payee"
		assert header.comment == nil
	end


	# Account Parser Tests

	test "Sub-account is any alphanumeric" do
		{:ok, _, sub} = ExParsec.parse_text "ABCabc123", P.sub_account
		assert sub == "ABCabc123"
	end

	test "Sub-account can start with digit" do
		{:ok, _, sub} = ExParsec.parse_text "123abcABC", P.sub_account
		assert sub == "123abcABC"
	end

	test "Multiple level account" do
		{:ok, _, accounts} = ExParsec.parse_text "Expenses:Food:Groceries", P.account
		assert accounts == ["Expenses", "Food", "Groceries"]
	end

	test "Single level account" do
		{:ok, _, accounts} = ExParsec.parse_text "Expenses", P.account
		assert accounts == ["Expenses"]
	end


	# Quantity Parser Tests

	test "Negative quantity with no fractional part" do
		{:ok, _, qty} = ExParsec.parse_text "-1,110", P.quantity
		assert qty == D.new("-1110")
	end

	test "Positive quantity with no factional part" do
		{:ok, _, qty} = ExParsec.parse_text "2,314", P.quantity
		assert qty == D.new("2314")
	end

	test "Negative quantity with fractional part" do
		{:ok, _, qty} = ExParsec.parse_text "-1,110.38", P.quantity
		assert qty == D.new("-1110.38")
	end

	test "Positive quantity with factional part" do
		{:ok, _, qty} = ExParsec.parse_text "24521.793", P.quantity
		assert qty == D.new("24521.793")
	end


	# Symbol Parser Tests

	test "Quoted symbol \"MTF5004\"" do
		{:ok, _, symbol} = ExParsec.parse_text "\"MTF5004\"", P.quoted_symbol
		assert symbol.value == "MTF5004"
		assert symbol.quoted == true
	end

	test "Unquoted symbol $" do
		{:ok, _, symbol} = ExParsec.parse_text "$", P.unquoted_symbol
		assert symbol.value == "$"
		assert symbol.quoted == false
	end

	test "Unquoted symbol US$" do
		{:ok, _, symbol} = ExParsec.parse_text "US$", P.unquoted_symbol
		assert symbol.value == "US$"
		assert symbol.quoted == false
	end

	test "Unquoted symbol AAPL" do
		{:ok, _, symbol} = ExParsec.parse_text "AAPL", P.unquoted_symbol
		assert symbol.value == "AAPL"
		assert symbol.quoted == false
	end

	test "Unquoted symbol in $13,245.00" do
		{:ok, _, symbol} = ExParsec.parse_text "$13,245.00", P.unquoted_symbol
		assert symbol.value == "$"
		assert symbol.quoted == false
	end

	test "Symbol that is quoted" do
		{:ok, _, symbol} = ExParsec.parse_text "\"MUT231\"", P.symbol
		assert symbol.value == "MUT231"
		assert symbol.quoted == true
	end

	test "Symbol that is unquoted" do
		{:ok, _, symbol} = ExParsec.parse_text "$", P.symbol
		assert symbol.value == "$"
		assert symbol.quoted == false
	end


	# Amount Parser Tests

	test "Amount symbol then quantity with whitespace" do
		{:ok, _, amount} = ExParsec.parse_text "$ 13,245.00", P.amount_symbol_then_quantity
		assert amount.qty == D.new("13245.00")
		assert amount.symbol == %Symbol{value: "$", quoted: false}
		assert amount.format == :symbol_left_with_space
	end

	test "Amount symbol then quantity no whitespace" do
		{:ok, _, amount} = ExParsec.parse_text "$13,245.00", P.amount_symbol_then_quantity
		assert amount.qty == D.new("13245.00")
		assert amount.symbol == %Symbol{value: "$", quoted: false}
		assert amount.format == :symbol_left_no_space
	end

	test "Amount quantity then symbol with whitespace" do
		{:ok, _, amount} = ExParsec.parse_text "13,245.463 AAPL", P.amount_quantity_then_symbol
		assert amount.qty == D.new("13245.463")
		assert amount.symbol == %Symbol{value: "AAPL", quoted: false}
		assert amount.format == :symbol_right_with_space
	end

	test "Amount quantity then symbol no whitespace" do
		{:ok, _, amount} = ExParsec.parse_text "13,245.463\"MUTF803\"", P.amount_quantity_then_symbol
		assert amount.qty == D.new("13245.463")
		assert amount.symbol == %Symbol{value: "MUTF803", quoted: true}
		assert amount.format == :symbol_right_no_space
	end

	test "Amount $13,255.22" do
		{:ok, _, amount} = ExParsec.parse_text "$13,255.22", P.amount
		assert amount.qty == D.new("13255.22")
		assert amount.symbol == %Symbol{value: "$", quoted: false}
		assert amount.format == :symbol_left_no_space
	end

	test "Amount 4.256 \"MUTF514\"" do
		{:ok, _, amount} = ExParsec.parse_text "4.256 \"MUTF514\"", P.amount
		assert amount.qty == D.new("4.256")
		assert amount.symbol == %Symbol{value: "MUTF514", quoted: true}
		assert amount.format == :symbol_right_with_space
	end

	test "Amount inferred" do
		{:ok, _, result} = ExParsec.parse_text "", P.amount
		assert result == :infer_amount
	end


	# Posting Parser Tests

	test "Posting with all components" do
		{:ok, _, posting} = ExParsec.parse_text "\tAssets:Savings\t$45.00\t;comment", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Savings"]
		assert posting.amount == %Amount{qty: D.new("45.00"),
																	 symbol: %Symbol{value: "$", quoted: false},
																	 format: :symbol_left_no_space}
		assert posting.comment == "comment"
	end

	test "Posting with all components -- commodity" do
		{:ok, _, posting} = ExParsec.parse_text "\tAssets:Investments\t13.508 \"MUTF514\"\t;comment", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Investments"]
		assert posting.amount == %Amount{qty: D.new("13.508"),
																		 symbol: %Symbol{value: "MUTF514", quoted: true},
																		 format: :symbol_right_with_space}
		assert posting.comment == "comment"
	end

	test "Posting with whitespace but no comment" do
		{:ok, _, posting} = ExParsec.parse_text "\tAssets:Savings\t$45.00\t", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Savings"]
		assert posting.amount == %Amount{qty: D.new("45.00"),
																		 symbol: %Symbol{value: "$", quoted: false},
																		 format: :symbol_left_no_space}
		assert posting.comment == nil
	end

	test "Posting with no whitespace or comment" do
		{:ok, _, posting} = ExParsec.parse_text "\tAssets:Savings\t$45.00", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Savings"]
		assert posting.amount == %Amount{qty: D.new("45.00"),
																		 symbol: %Symbol{value: "$", quoted: false},
																		 format: :symbol_left_no_space}
		assert posting.comment == nil
	end

	test "Posting with inferred amount" do
		{:ok, _, posting} = ExParsec.parse_text " Assets:Savings ;comment ", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Savings"]
		assert posting.amount == :infer_amount
		assert posting.comment == "comment "
	end

	test "Posting with inferred amount, whitespace, no comment" do
		{:ok, _, posting} = ExParsec.parse_text " Assets:Savings ", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Savings"]
		assert posting.amount == :infer_amount
		assert posting.comment == nil
	end

	test "Posting with inferred amount, no whitespace, no comment" do
		{:ok, _, posting} = ExParsec.parse_text " Assets:Savings", P.posting
		assert posting.header == nil
		assert posting.line_number == 1
		assert posting.account == ["Assets", "Savings"]
		assert posting.amount == :infer_amount
		assert posting.comment == nil
	end


	# Transaction Parsers Tests

	test "Comment line with leading whitespace" do
		{:ok, _, result} = ExParsec.parse_text "  ;comment", P.comment_line
		assert result == {:comment, "comment"}
	end

	test "Comment line with no leading whitespace" do
		{:ok, _, result} = ExParsec.parse_text ";comment", P.comment_line
		assert result == {:comment, "comment"}
	end

	test "Posting or comment line: comment" do
		{:ok, _, result} =
			ExParsec.parse_text ";  comment\n", P.posting_or_comment_line
		assert result == {:comment, "  comment"}
	end

	test "Posting or comment line: posting" do
		{:ok, _, result} =
			ExParsec.parse_text "  Assets:Savings  $45.00\n",
												  P.posting_or_comment_line
		assert Posting.posting?(result)
	end

	test "Transaction: Basic" do
		{:ok, _, {header, postings}} =
			ExParsec.parse_text(
				"""
				2015/03/06 * Basic transaction ;comment
				  Expenses:Groceries		$45.00
				  Liabilities:Credit
				""",
				P.transaction)
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 3, day: 6}
		assert header.status == :cleared
		assert header.payee == "Basic transaction "
		assert header.comment == "comment"
		assert Enum.count(postings) == 2
	end


end
