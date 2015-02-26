defmodule Terminals do

	@doc """
	Open parenthesis.
	"""
	@spec open_parenthesis(String.codepoint()) :: boolean()
	def open_parenthesis(c) do
		c == "("
	end

	@doc """
	Close parenthesis.
	"""
	@spec close_parenthesis(String.codepoint()) :: boolean()
	def close_parenthesis(c) do
		c == ")"
	end

	@doc """
	Semi-colon.
	"""
	@spec semicolon(String.codepoint()) :: boolean()
	def semicolon(c) do
		c == ";"
	end

	@doc """
	Colon.
	"""
	@spec colon(String.codepoint()) :: boolean()
	def colon(c) do
		c == ":"
	end

	@doc """
	Dash.
	"""
	@spec dash(String.codepoint()) :: boolean()
	def dash(c) do
		c == "-"
	end

	@doc """
	Quote.
	"""
	@spec quote_terminal(String.codepoint()) :: boolean()
	def quote_terminal(c) do
		c == "\""
	end

	@doc """
	Newline.
	"""
	@spec newline(String.codepoint()) :: boolean()
	def newline(c) do
		c == "\r" or c == "\n"
	end

	@doc """
	Space.
	"""
	@spec space(String.codepoint()) :: boolean()
	def space(c) do
		c == " "
	end

	@doc """
	Tab.
	"""
	@spec tab(String.codepoint()) :: boolean()
	def tab(c) do
		c == "\t"
	end

	@doc """
	Whitespace.
	"""
	@spec whitespace(String.codepoint()) :: boolean()
	def whitespace(c) do
		space(c) or tab(c)
	end

	@doc """
	Digit.
	"""
	@spec digit(String.codepoint()) :: boolean()
	def digit(<<c :: utf8>>) do
		c in ?0 .. ?0
	end

	@doc """
	Terminals for date separator.
	"""
	@spec date_separator(String.codepoint()) :: boolean()
	def date_separator(c) do
		c == "/" or c == "-"
	end

	@doc """
	Terminals for entry status flags.
	"""
	@spec entry_status(String.codepoint()) :: boolean()
	def entry_status(c) do
		c == "*" or c == "!"
	end

	@doc """
	Terminals for entry code.
	"""
	@spec code_character(String.codepoint()) :: boolean()
	def code_character(c) do
		!newline(c) and !close_parenthesis(c)
	end

	@doc """
	Terminals for payee.
	"""
	@spec payee_character(String.codepoint()) :: boolean()
	def payee_character(c) do
		!newline(c) and !semicolon(c)
	end

	@doc """
	Terminals for comment.
	"""
	@spec comment_character(String.codepoint()) :: boolean()
	def comment_character(c) do
		!newline(c)
	end

	@doc """
	Terminals for a quoted symbol.
	"""
	@spec quoted_symbol_character(String.codepoint()) :: boolean()
	def quoted_symbol_character(c) do
		!newline(c) and !quote_terminal(c)
	end

	@doc """
	Terminals for an unquoted symbol.
	"""
	@spec unquoted_symbol_character(String.codepoint()) :: boolean()
	def unquoted_symbol_character(c) do
		codepoints = String.codepoints("-0123456789; \"\t\r\n")
		!(c in codepoints)
	end

end