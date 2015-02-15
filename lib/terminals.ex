defmodule Terminals do

	@doc """
	Terminals for date separator.
	"""
	@spec date_sep(String.codepoint()) :: boolean()
	def date_sep(c) do
		c == "/" or c == "-"
	end

	@doc """
	Terminals for transaction status flags.
	"""
	@spec transaction_status(String.codepoint()) :: boolean()
	def transaction_status(c) do
		c == "*" or c == "!"
	end
	
end