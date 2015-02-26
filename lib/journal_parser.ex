defmodule JournalParser do
	import ExParsec.Base
	import ExParsec.Text
	import ExParsec.Helpers
	import Terminals
	alias Types.Date
	alias Types.EntryHeader

	# Helpers

	@doc """
	Whitespace.
	"""
	@spec whitespace() :: ExParsec.t(term(), :whitespace | :no_whitespace)
	defmparser whitespace() do
		list <- many(satisfy("whitespace", &whitespace/1))

		case list do
			_ when length(list) > 0 -> return :whitespace
			_												-> return :no_whitespace
		end
	end

	@doc """
	Mandatory whitespace (one or more whitespace characters).
	"""
	@spec mandatory_whitespace() :: ExParsec.t(term(), :whitespace)
	defmparser mandatory_whitespace() do
		many1(satisfy("whitespace", &whitespace/1))
		return :whitespace
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
	@spec date() :: ExParsec.t(term(), Date.t())
	defmparser date() do
		year <- year()
		satisfy("date separator", &date_separator/1)
		month <- month()
		satisfy("date separator", &date_separator/1)
		day <- day()
		return %Date{year: year, month: month, day: day}
	end


	# Entry Status Parser

	@doc """
	Expects and parses a entry status (cleared or uncleared).
	"""
	@spec entry_status() :: ExParsec.t(term(), :cleared | :uncleared)
	defmparser entry_status() do
		status <- satisfy("entry status flag", &entry_status/1)

		case status do
			"*" -> return :cleared
			_   -> return :uncleared
		end
	end


	# Code Parser

	@doc """
	Expects and parses an entry code between parentheses.
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


	# Entry Header Parser

	@doc """
	Expects and parses an entry header (first line).
	"""
	@spec entry_header() :: ExParsec.t(term(), EntryHeader.t())
	defmparser entry_header() do
		line_num <- line_number()
		date <- date()
		whitespace()
		status <- entry_status()
		whitespace()
		code <- option(code())
		whitespace()
		payee <- payee()
		comment <- option(comment())

		return %EntryHeader{line_number: line_num,
											  date: date,
											  status: status,
											  code: code,
											  payee: payee,
											  comment: comment}
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
		char(".")
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


	# Symbol Parsers

	@doc """
	Expects and parses a quoted symbol.
	"""
	@spec quoted_symbol() :: ExParsec.t(term(), {:quoted, String.t()})
	defmparser quoted_symbol() do
		satisfy("quote", &quote_terminal/1)
		symbol_list <- many1(satisfy("quoted symbol character", &quoted_symbol_character/1))
		satisfy("quote", &quote_terminal/1)

		return {:quoted, Enum.join(symbol_list)}
	end

	@doc """
	Expects and parses an unquoted symbol. Unquoted symbols have a restricted character set.
	"""
	@spec unquoted_symbol() :: ExParsec.t(term(), {:unquoted, String.t()})
	defmparser unquoted_symbol() do
		symbol_list <- many1(satisfy("unquoted symbol character", &unquoted_symbol_character/1))
		return {:unquoted, Enum.join(symbol_list)}
	end

	@doc """
	Expects and parses a quoted or unquoted symbol.
	"""
	@spec symbol() :: ExParsec.t(term(), {:quoted | :unquoted, String.t()})
	defmparser symbol() do
		either(quoted_symbol(), unquoted_symbol())
	end


	# Amount Parsers

	# An amount is a quantity and a symbol representing the commodity.
	# An amount may be specified the following ways:
	#		{symbol}{quantity}  :: symbol on left with no whitespace between
	#   {symbol} {quantity} :: symbol on left with whitespace between
	#		{quantity}{symbol}  :: symbol on right with no whitespace between
	#   {quantity} {symbol} :: sybmol on right with whitespace between

	@doc """
	Expects and parses an amount in the format of symbol then quantity.
	"""
	# !!! TODO: NEED TO DEFINE TYPE SPEC HERE !!!
	#@spec amount_symbol_then_quantity() :: ExParsec.t(term(), )
	defmparser amount_symbol_then_quantity() do
		symbol <- symbol()
		ws <- whitespace()
		qty <- quantity()

		case ws do
			:whitespace    -> return {:symbol_left_with_space, qty, symbol}
			:no_whitespace -> return {:symbol_left_no_space, qty, symbol}
		end
	end

	@doc """
	Expects and parses an amount in the format of quantity then symbol.
	"""
	# !!! TODO: NEED TO DEFINE TYPE SPEC HERE !!!
	#@spec amount_quantity_then_symbol() :: ExParsec.t(term(), )
	defmparser amount_quantity_then_symbol() do
		qty <- quantity()
		ws <- whitespace()
		symbol <- symbol()

		case ws do
			:whitespace	   -> return {:symbol_right_with_space, qty, symbol}
			:no_whitespace -> return {:symbol_right_no_space, qty, symbol}
		end
	end

	@doc """
	Expects and parses an amount.
	"""
	# !!! TODO: NEED TO DEFINE TYPE SPEC HERE !!!
	#@spec amount() :: ExParsec.t(term(), )
	defmparser amount() do
		amount <- option(either(amount_symbol_then_quantity(), amount_quantity_then_symbol()))

		case amount do
			{:ok, amount} -> return amount
			nil           -> return :infer_amount
		end
	end

end