defmodule JournalParserTest do
	use ExUnit.Case, async: true
	import JournalParser
	
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

end