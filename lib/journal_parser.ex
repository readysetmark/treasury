defmodule JournalParser do
	import ExParsec.Base
	import ExParsec.Text
	import ExParsec.Helpers
	import Terminals

	# Helpers

	@doc """
	Skips whitespace.
	"""
	@spec skip_whitespace() :: ExParsec.t(term(), nil)
	defmparser skip_whitespace() do
		skip_many(satisfy("whitespace", &whitespace/1))
	end


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


	# Transaction Header Parser

	@doc """
	Expects and parses a transaction header (first line).
	"""
	@spec transaction_header() :: 
				ExParsec.t(term(), {integer(), {integer(), integer(), integer()},
									 String.t(), {:ok, String.t()} | nil, String.t(),
									 {:ok, String.t()} | nil})
	defmparser transaction_header() do
		line_num <- line_number()
		date <- date()
		skip_whitespace()
		status <- transaction_status()
		skip_whitespace()
		code <- option(code())
		skip_whitespace()
		payee <- payee()
		comment <- option(comment())

		return {line_num, date, status, code, payee, comment}
	end


	# Account Parsers

	# Very simple account parsers right now. Account must be alphanumeric.

	@doc """
	Expects and parses a sub-account name.
	"""
	@spec sub_account() :: ExParsec.t(term(), String.t())
	defmparser sub_account() do
		list <- many1(alphanumeric())
		return Enum.join(list)
	end

	@doc """
	Expects and parses a full account name.
	"""
	@spec account() :: ExParsec.t(term(), [String.t()])
	defmparser account() do
		sep_by1(sub_account(), satisfy("account separator", &colon/1))
	end


	# Quantity Parsers

	@doc """
	Expects and parses an optional negative sign. If sign not provided, :positive is assumed.
	"""
	@spec sign() :: ExParsec.t(term(), :positive | :negative)
	defmparser sign() do
		neg_sign <- option(satisfy("negative sign", &dash/1))

		case neg_sign do
			{:ok, "-"} -> return :negative
			_ 				 -> return :positive
		end
	end

	@doc """
	Expects and parses an integer (allows comma-separators).
	"""
	@spec integer() :: ExParsec.t(term(), String.t())
	defmparser integer() do
		first_digit <- digit()
		digit_list <- many(either(digit(), char(",")))

		return Enum.join([first_digit|digit_list])
	end

	@doc """
	Expects and parses a fractional part.
	"""
	@spec fractional_part() :: ExParsec.t(term(), String.t())
	defmparser fractional_part() do
		separator <- char(".")
		digit_list <- many1(digit())

		return Enum.join(digit_list)
	end

	@doc """
	Expects and parses a negative or positive quantity which may have a fractional part.
	"""
	@spec quantity() :: ExParsec.t(term(), {String.t(), String.t(), {:ok, String.t()} | nil})
	defmparser quantity() do
		sign <- sign()
		integer_part <- integer()
		fractional_part <- option(fractional_part())

		return {sign, integer_part, fractional_part}
	end


	# Amount Parsers

	# An amount is a quantity and a symbol representing the commodity.
	# An amount may be specified the following ways:
	#		- {symbol}{quantity} :: symbol on the left with no space between
	#		



end