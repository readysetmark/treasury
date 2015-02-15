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
	Newline.
	"""
	@spec newline(String.codepoint()) :: boolean()
	def newline(c) do
		c == "\r" or c == "\n"
	end

	@doc """
	Terminals for date separator.
	"""
	@spec date_separator(String.codepoint()) :: boolean()
	def date_separator(c) do
		c == "/" or c == "-"
	end

	@doc """
	Terminals for transaction status flags.
	"""
	@spec transaction_status(String.codepoint()) :: boolean()
	def transaction_status(c) do
		c == "*" or c == "!"
	end

	@doc """
	Terminals for transaction code.
	"""
	@spec code_character(String.codepoint()) :: boolean()
	def code_character(c) do
		!newline(c) and !close_parenthesis(c)
	end

end