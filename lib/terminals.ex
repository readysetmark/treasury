defmodule Terminals do
	
	@doc """
	Terminals for date separator.
	"""
	@spec date_sep(String.codepoint()) :: boolean()
	def date_sep(c) do
		c == "/" or c == "-"
	end

end