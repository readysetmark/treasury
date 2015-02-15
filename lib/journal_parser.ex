defmodule JournalParser do
	import ExParsec.Base
	import ExParsec.Text
	import ExParsec.Helpers
	import Terminals

	# Line Number Parser

	@doc """
	Get current line number.
	"""
	@spec line_number() :: ExParsec.t(term(), integer())
	defmparser line_number() do
		pos <- get_position()
		return pos.line
	end


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
		satisfy("date separator", &date_separator/1)
		month <- month()
		satisfy("date separator", &date_separator/1)
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


	# Code Parser

	@doc """
	Expects and parses a transaction code between parentheses.
	"""
	@spec code() :: ExParsec.t(term(), String.t())
	defmparser code() do
		satisfy("(", &open_parenthesis/1)
		code_list <- many(satisfy("code character", &code_character/1))
		satisfy(")", &close_parenthesis/1)
		return Enum.join(code_list)
	end


	# Payee Parser

	@doc """
	Expects and parses a payee.
	"""
	@spec payee() :: ExParsec.t(term(), String.t())
	defmparser payee() do
		payee_list <- many1(satisfy("payee character", &payee_character/1))
		return Enum.join(payee_list)
	end


	# Comment Parser
	@doc """
	Expects and parses a comment that runs to the end of the line.
	"""
	@spec comment() :: ExParsec.t(term(), String.t())
	defmparser comment() do
		satisfy(";", &semicolon/1)
		comment_list <- many(satisfy("comment character", &comment_character/1))
		return Enum.join(comment_list)
	end

end