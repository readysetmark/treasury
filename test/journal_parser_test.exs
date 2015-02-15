defmodule JournalParserTest do
	use ExUnit.Case, async: true
	import JournalParser

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

end