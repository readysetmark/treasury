defmodule JournalParserTest do
	use ExUnit.Case, async: true
	import JournalParser

	# Helpers Tests

	test "Skip whitespace skips spaces" do
		{:ok, _, result} = ExParsec.parse_text "   ", skip_whitespace
		assert result == nil
	end

	test "Skip whitespace skips tabs" do
		{:ok, _, result} = ExParsec.parse_text "\t\t\t", skip_whitespace
		assert result == nil
	end

	test "Skip whitespace skips tabs and spaces" do
		{:ok, _, result} = ExParsec.parse_text " \t\t  ", skip_whitespace
		assert result == nil
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
		{:ok, _, {year, month, day}} = ExParsec.parse_text "2015/02/14", date
		assert year == 2015
		assert month == 2
		assert day == 14
	end

	test "Parse date with dashes" do
		{:ok, _, {year, month, day}} = ExParsec.parse_text "2015-02-14", date
		assert year == 2015
		assert month == 2
		assert day == 14
	end


	# Transaction Status Parser Tests

	test "* denotes cleared transaction" do
		{:ok, _, status} = ExParsec.parse_text "*", transaction_status
		assert status == :cleared
	end

	test "! denotes uncleared transaction" do
		{:ok, _, status} = ExParsec.parse_text "!", transaction_status
		assert status == :uncleared
	end


	# Code Parser Tests

	test "Long transaction code" do
		{:ok, _, code} = ExParsec.parse_text "(conf# ABC-123-def)", code
		assert code == "conf# ABC-123-def"
	end

	test "Short transaction code" do
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


	# Transaction Header Parser Tests

	test "Full transaction header" do
		{:ok, _, {line_num, date, status, code, payee, comment}} =
			ExParsec.parse_text "2015/02/15 * (conf# abc-123) Payee ;Comment", transaction_header
		assert line_num == 1
		assert date == {2015, 2, 15}
		assert status == :cleared
		assert code == {:ok, "conf# abc-123"}
		assert payee == "Payee "
		assert comment == {:ok, "Comment"}
	end

	test "Transaction header with code and no comment" do
		{:ok, _, {line_num, date, status, code, payee, comment}} =
			ExParsec.parse_text "2015/02/15 ! (conf# abc-123) Payee", transaction_header
		assert line_num == 1
		assert date == {2015, 2, 15}
		assert status == :uncleared
		assert code == {:ok, "conf# abc-123"}
		assert payee == "Payee"
		assert comment == nil
	end

	test "Transaction header with comment and no code" do
		{:ok, _, {line_num, date, status, code, payee, comment}} =
			ExParsec.parse_text "2015/02/15 * Payee ;Comment", transaction_header
		assert line_num == 1
		assert date == {2015, 2, 15}
		assert status == :cleared
		assert code == nil
		assert payee == "Payee "
		assert comment == {:ok, "Comment"}
	end

	test "Transaction header with no code or comment" do
		{:ok, _, {line_num, date, status, code, payee, comment}} =
			ExParsec.parse_text "2015/02/15 * Payee", transaction_header
		assert line_num == 1
		assert date == {2015, 2, 15}
		assert status == :cleared
		assert code == nil
		assert payee == "Payee"
		assert comment == nil
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

end