defmodule Types.Date do
	defstruct year: nil,
						month: nil,
						day: nil

	@type t :: %__MODULE__{year: integer(),
									 			 month: integer(),
									 			 day: integer()}
end
