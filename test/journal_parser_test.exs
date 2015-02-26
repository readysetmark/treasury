defmodule JournalParserTest do
	use ExUnit.Case, async: true
	import JournalParser
	alias Types.Date

	# Helpers Tests

	test "Whitespace just spaces" do
		{:ok, _, result} = ExParsec.parse_text "   ", whitespace
		assert result == :whitespace
	end

	test "Whitespace just tabs" do
		{:ok, _, result} = ExParsec.parse_text "\t\t\t", whitespace
		assert result == :whitespace
	end

	test "Whitespace tabs and spaces" do
		{:ok, _, result} = ExParsec.parse_text " \t\t  ", whitespace
		assert result == :whitespace
	end

	test "Whitespace nothing" do
		{:ok, _, result} = ExParsec.parse_text "", whitespace
		assert result == :no_whitespace
	end

	test "Mandatory whitespace" do
		{:ok, _, result} = ExParsec.parse_text " ", mandatory_whitespace
		assert result == :whitespace
	end

	test "Mandatory whitespace missing" do
		{result, _} = ExParsec.parse_text "", mandatory_whitespace
		assert result == :error
	end


	# Line Number Parser Tests

	test "First line is 1" do
		{:ok, _, line_num} = ExParsec.parse_text "One Line", line_number
		assert line_num == 1
	end

	
	# Date Parser Tests

	test "Parse 4-digit year" do
		{:ok, _, year} = ExParsec.parse_text "2015", year
		assert year == 2015
	end

	test "Parse 2-digit month" do
		{:ok, _, month} = ExParsec.parse_text "02", month
		assert month == 2
	end

	test "Parse 2-digit day" do
		{:ok, _, day} = ExParsec.parse_text "14", day
		assert day == 14
	end

	test "Parse date with slashes" do
		{:ok, _, date} = ExParsec.parse_text "2015/02/14", date
		assert date.year == 2015
		assert date.month == 2
		assert date.day == 14
	end

	test "Parse date with dashes" do
		{:ok, _, date} = ExParsec.parse_text "2015-02-14", date
		assert date.year == 2015
		assert date.month == 2
		assert date.day == 14
	end


	# Entry Status Parser Tests

	test "* denotes cleared entry" do
		{:ok, _, status} = ExParsec.parse_text "*", entry_status
		assert status == :cleared
	end

	test "! denotes uncleared entry" do
		{:ok, _, status} = ExParsec.parse_text "!", entry_status
		assert status == :uncleared
	end


	# Code Parser Tests

	test "Long entry code" do
		{:ok, _, code} = ExParsec.parse_text "(conf# ABC-123-def)", code
		assert code == "conf# ABC-123-def"
	end

	test "Short entry code" do
		{:ok, _, code} = ExParsec.parse_text "(89)", code
		assert code == "89"
	end

	test "Empty code" do
		{:ok, _, code} = ExParsec.parse_text "()", code
		assert code == ""
	end


	# Payee Parser Tests

	test "Long payee" do
		{:ok, _, payee} = ExParsec.parse_text "WonderMart - groceries, toiletries, kitchen supplies", payee
		assert payee == "WonderMart - groceries, toiletries, kitchen supplies"
	end

	test "Short payee" do
		{:ok, _, payee} = ExParsec.parse_text "WonderMart", payee
		assert payee == "WonderMart"
	end

	test "Single character payee" do
		{:ok, _, payee} = ExParsec.parse_text "Z", payee
		assert payee == "Z"
	end

	test "Payee must have at least one character" do
		{result, _} = ExParsec.parse_text "", payee
		assert result == :error
	end


	# Comment Parser Tests

	test "Comment with leading space" do
		{:ok, _, comment} = ExParsec.parse_text "; Comment", comment
		assert comment == " Comment"
	end

	test "Comment with no leading space" do
		{:ok, _, comment} = ExParsec.parse_text ";Comment", comment
		assert comment == "Comment"
	end

	test "Empty comment" do
		{:ok, _, comment} = ExParsec.parse_text ";", comment
		assert comment == ""
	end


	# Entry Header Parser Tests

	test "Full entry header" do
		{:ok, _, header} = 
			ExParsec.parse_text "2015/02/15 * (conf# abc-123) Payee ;Comment", 
													entry_header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :cleared
		assert header.code == {:ok, "conf# abc-123"}
		assert header.payee == "Payee "
		assert header.comment == {:ok, "Comment"}
	end

	test "Entry header with code and no comment" do
		{:ok, _, header} =
			ExParsec.parse_text "2015/02/15 ! (conf# abc-123) Payee", entry_header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :uncleared
		assert header.code == {:ok, "conf# abc-123"}
		assert header.payee == "Payee"
		assert header.comment == nil
	end

	test "Entry header with comment and no code" do
		{:ok, _, header} =
			ExParsec.parse_text "2015/02/15 * Payee ;Comment", entry_header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :cleared
		assert header.code == nil
		assert header.payee == "Payee "
		assert header.comment == {:ok, "Comment"}
	end

	test "Entry header with no code or comment" do
		{:ok, _, header} =
			ExParsec.parse_text "2015/02/15 * Payee", entry_header
		assert header.line_number == 1
		assert header.date == %Date{year: 2015, month: 2, day: 15}
		assert header.status == :cleared
		assert header.code == nil
		assert header.payee == "Payee"
		assert header.comment == nil
	end


	# Account Parser Tests

	test "Sub-account is any alphanumeric" do
		{:ok, _, sub} = ExParsec.parse_text "ABCabc123", sub_account
		assert sub == "ABCabc123"
	end

	test "Sub-account can start with digit" do
		{:ok, _, sub} = ExParsec.parse_text "123abcABC", sub_account
		assert sub == "123abcABC"
	end

	test "Multiple level account" do
		{:ok, _, accounts} = ExParsec.parse_text "Expenses:Food:Groceries", account
		assert accounts == ["Expenses", "Food", "Groceries"]
	end

	test "Single level account" do
		{:ok, _, accounts} = ExParsec.parse_text "Expenses", account
		assert accounts == ["Expenses"]
	end


	# Quantity Parser Tests

	test "Negative sign" do
		{:ok, _, sign} = ExParsec.parse_text "-", sign
		assert sign == :negative
	end

	test "Positive sign" do
		{:ok, _, sign} = ExParsec.parse_text "", sign
		assert sign == :positive
	end

	test "Simple integer" do
		{:ok, _, int} = ExParsec.parse_text "43", integer
		assert int == "43"
	end

	test "Integer with separator" do
		{:ok, _, int} = ExParsec.parse_text "1,204", integer
		assert int == "1,204"
	end

	test "Fractional part (two digits)" do
		{:ok, _, frac} = ExParsec.parse_text ".98", fractional_part
		assert frac == "98"
	end

	test "Fractional part (three digits)" do
		{:ok, _, frac} = ExParsec.parse_text ".806", fractional_part
		assert frac == "806"
	end

	test "Negative quantity with no fractional part" do
		{:ok, _, {sign, int, frac}} = ExParsec.parse_text "-1,110", quantity
		assert sign == :negative
		assert int == "1,110"
		assert frac == nil
	end

	test "Positive quantity with no factional part" do
		{:ok, _, {sign, int, frac}} = ExParsec.parse_text "2,314", quantity
		assert sign == :positive
		assert int == "2,314"
		assert frac == nil
	end

	test "Negative quantity with fractional part" do
		{:ok, _, {sign, int, frac}} = ExParsec.parse_text "-1,110.38", quantity
		assert sign == :negative
		assert int == "1,110"
		assert frac == {:ok, "38"}
	end

	test "Positive quantity with factional part" do
		{:ok, _, {sign, int, frac}} = ExParsec.parse_text "24521.793", quantity
		assert sign == :positive
		assert int == "24521"
		assert frac == {:ok, "793"}
	end


	# Symbol Parser Tests

	test "Quoted symbol \"MTF5004\"" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "\"MTF5004\"", quoted_symbol
		assert type == :quoted
		assert symbol == "MTF5004"
	end

	test "Unquoted symbol $" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "$", unquoted_symbol
		assert type == :unquoted
		assert symbol == "$"
	end

	test "Unquoted symbol US$" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "US$", unquoted_symbol
		assert type == :unquoted
		assert symbol == "US$"
	end

	test "Unquoted symbol AAPL" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "AAPL", unquoted_symbol
		assert type == :unquoted
		assert symbol == "AAPL"
	end

	test "Unquoted symbol in $13,245.00" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "$13,245.00", unquoted_symbol
		assert type == :unquoted
		assert symbol == "$"
	end

	test "Symbol that is quoted" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "\"MUT231\"", symbol
		assert type == :quoted
		assert symbol == "MUT231"
	end

	test "Symbol that is unquoted" do
		{:ok, _, {type, symbol}} = ExParsec.parse_text "$", symbol
		assert type == :unquoted
		assert symbol == "$"
	end


	# Amount Parser Tests

	test "Amount symbol then quantity with whitespace" do
		{:ok, _, {desc, qty, symbol}} = ExParsec.parse_text "$ 13,245.00", amount_symbol_then_quantity
		assert desc == :symbol_left_with_space
		assert qty == {:positive, "13,245", {:ok, "00"}}
		assert symbol == {:unquoted, "$"}
	end

	test "Amount symbol then quantity no whitespace" do
		{:ok, _, {desc, qty, symbol}} = ExParsec.parse_text "$13,245.00", amount_symbol_then_quantity
		assert desc == :symbol_left_no_space
		assert qty == {:positive, "13,245", {:ok, "00"}}
		assert symbol == {:unquoted, "$"}
	end

	test "Amount quantity then symbol with whitespace" do
		{:ok, _, {desc, qty, symbol}} = ExParsec.parse_text "13,245.463 AAPL", amount_quantity_then_symbol
		assert desc == :symbol_right_with_space
		assert qty == {:positive, "13,245", {:ok, "463"}}
		assert symbol == {:unquoted, "AAPL"}
	end

	test "Amount quantity then symbol no whitespace" do
		{:ok, _, {desc, qty, symbol}} = ExParsec.parse_text "13,245.463\"MUTF803\"", amount_quantity_then_symbol
		assert desc == :symbol_right_no_space
		assert qty == {:positive, "13,245", {:ok, "463"}}
		assert symbol == {:quoted, "MUTF803"}
	end

	test "Amount $13,255.22" do
		{:ok, _, {desc, qty, symbol}} = ExParsec.parse_text "$13,255.22", amount
		assert desc == :symbol_left_no_space
		assert qty == {:positive, "13,255", {:ok, "22"}}
		assert symbol == {:unquoted, "$"}
	end

	test "Amount 4.256 \"MUTF514\"" do
		{:ok, _, {desc, qty, symbol}} = ExParsec.parse_text "4.256 \"MUTF514\"", amount
		assert desc == :symbol_right_with_space
		assert qty == {:positive, "4", {:ok, "256"}}
		assert symbol == {:quoted, "MUTF514"}
	end

	test "Amount inferred" do
		{:ok, _, result} = ExParsec.parse_text "", amount
		assert result == :infer_amount
	end

end