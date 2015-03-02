defmodule JournalParser do
	import ExParsec.Base
	import ExParsec.Text
	import ExParsec.Helpers
	alias Decimal, as: D
	alias Terminals, as: T
	alias Types
	alias Types.Symbol
	alias Types.Amount
	alias Types.Date
	alias Types.EntryHeader


	# Helpers

	@doc """
	Extracts value from the result of applying an optional parser.
	An optional parser returns {:ok, <value>} or nil. This function will return
	<value> or nil.
	"""
	@spec get_optional(val :: {:ok, any()} | nil, default :: any()) :: any()
	def get_optional(val, default \\ nil) do
		case val do
			{:ok, v} -> v
			_				 -> default
		end
	end

	@doc """
	Whitespace.
	"""
	@spec whitespace() :: ExParsec.t(term(), :whitespace | :no_whitespace)
	defmparser whitespace() do
		list <- many(satisfy("whitespace", &T.whitespace/1))

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
		many1(satisfy("whitespace", &T.whitespace/1))
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
		satisfy("date separator", &T.date_separator/1)
		month <- month()
		satisfy("date separator", &T.date_separator/1)
		day <- day()
		return %Date{year: year, month: month, day: day}
	end


	# Entry Status Parser

	@doc """
	Expects and parses a entry status (cleared or uncleared).
	"""
	@spec entry_status() :: ExParsec.t(term(), Types.status())
	defmparser entry_status() do
		status <- satisfy("entry status flag", &T.entry_status/1)

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
		satisfy("(", &T.open_parenthesis/1)
		code_list <- many(satisfy("code character", &T.code_character/1))
		satisfy(")", &T.close_parenthesis/1)
		return Enum.join(code_list)
	end


	# Payee Parser

	@doc """
	Expects and parses a payee.
	"""
	@spec payee() :: ExParsec.t(term(), String.t())
	defmparser payee() do
		payee_list <- many1(satisfy("payee character", &T.payee_character/1))
		return Enum.join(payee_list)
	end


	# Comment Parser
	
	@doc """
	Expects and parses a comment that runs to the end of the line.
	"""
	@spec comment() :: ExParsec.t(term(), String.t())
	defmparser comment() do
		satisfy(";", &T.semicolon/1)
		comment_list <- many(satisfy("comment character", &T.comment_character/1))
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
											  code: get_optional(code),
											  payee: payee,
											  comment: get_optional(comment)}
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
		sep_by1(sub_account(), satisfy("account separator", &T.colon/1))
	end


	# Quantity Parsers

	@doc """
	Expects and parses a numeric quantity and returns a Decimal.
	"""
	@spec quantity() :: ExParsec.t(term(), D.t())
	defmparser quantity() do
		neg_sign <- option(satisfy("negative sign", &T.dash/1))
		first_digit <- digit()
		char_list <- many(choice([digit(), char(","), char(".")]))

		[get_optional(neg_sign, ""), first_digit, char_list]
		|> Enum.join
		|> String.replace(",", "")
		|> D.new()
		|> return
	end


	# Symbol Parsers

	@doc """
	Expects and parses a quoted symbol.
	"""
	@spec quoted_symbol() :: ExParsec.t(term(), Symbol.t())
	defmparser quoted_symbol() do
		satisfy("quote", &T.quote_terminal/1)
		symbol_list <- many1(satisfy("quoted symbol character", &T.quoted_symbol_character/1))
		satisfy("quote", &T.quote_terminal/1)

		return {:quoted, Enum.join(symbol_list)}
	end

	@doc """
	Expects and parses an unquoted symbol. Unquoted symbols have a restricted character set.
	"""
	@spec unquoted_symbol() :: ExParsec.t(term(), Symbol.t())
	defmparser unquoted_symbol() do
		symbol_list <- many1(satisfy("unquoted symbol character", &T.unquoted_symbol_character/1))
		return {:unquoted, Enum.join(symbol_list)}
	end

	@doc """
	Expects and parses a quoted or unquoted symbol.
	"""
	@spec symbol() :: ExParsec.t(term(), Symbol.t())
	defmparser symbol() do
		either(quoted_symbol(), unquoted_symbol())
	end


	# Amount Parsers

	@doc """
	Expects and parses an amount in the format of symbol then quantity.
	"""
	@spec amount_symbol_then_quantity() :: ExParsec.t(term(), Amount.t())
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
	@spec amount_quantity_then_symbol() :: ExParsec.t(term(), Amount.t())
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
	Expects and parses an optional amount. If no amount is found, it is assumed to
	be an inferred amount.

	An amount is a quantity and a symbol representing the commodity. An amount may
	be specified any of the following ways:

		<symbol><quantity>  :: symbol on left with no whitespace between
	  <symbol> <quantity> :: symbol on left with whitespace between
		<quantity><symbol>  :: symbol on right with no whitespace between
	  <quantity> <symbol> :: sybmol on right with whitespace between
	"""
	@spec amount() :: ExParsec.t(term(), Amount.t() | :infer_amount)
	defmparser amount() do
		amount <- option(either(amount_symbol_then_quantity(), amount_quantity_then_symbol()))

		case amount do
			{:ok, amount} -> return amount
			nil           -> return :infer_amount
		end
	end

end