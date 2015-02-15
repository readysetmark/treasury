defmodule JournalParser do
	import ExParsec.Base
	import ExParsec.Text
	import ExParsec.Helpers
	import Terminals


	# Date Parsers

	@doc """
	Expects and parses a 4 digit date.
	"""
	@spec year() :: ExParsec.t(term(), integer())
	defmparser year() do
		digit_list <- times(digit(), 4)
		return elem(Integer.parse(Enum.join(digit_list)), 0)
	end

	@doc """
	Expects and parses a 2 digit month.
	"""
	@spec month() :: ExParsec.t(term(), integer())
	defmparser month() do
		digit_list <- times(digit(), 2)
		return elem(Integer.parse(Enum.join(digit_list)), 0)
	end

	@doc """
	Expects and parses a 2 digit day.
	"""
	@spec day() :: ExParsec.t(term(), integer())
	defmparser day() do
		digit_list <- times(digit(), 2)
		return elem(Integer.parse(Enum.join(digit_list)), 0)
	end

	@doc """
	Expects and parses a date expressed as 2015/02/14 or 2015-02-14.
	"""
	@spec date() :: ExParsec.t(term(), {integer(), integer(), integer()})
	defmparser date() do
		year <- year()
		satisfy("date separator", &date_sep/1)
		month <- month()
		satisfy("date separator", &date_sep/1)
		day <- day()
		return {year, month, day}
	end


	# Transaction Status Parser

	@doc """
	Expects and parses a transaction status (cleared or uncleared).
	"""
	@spec transaction_status() :: ExParsec.t(term(), :cleared | :uncleared)
	defmparser transaction_status() do
		status <- satisfy("transaction status flag", &transaction_status/1)

		case status do
			"*" -> return :cleared
			_   -> return :uncleared
		end
	end
end