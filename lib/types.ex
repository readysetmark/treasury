defmodule Types do

	@type status :: :uncleared | :cleared

	defmodule Date do
		defstruct year: nil,
							month: nil,
							day: nil

		@type t :: %__MODULE__{year: integer(),
										 			 month: integer(),
										 			 day: integer()}
	end

	defmodule EntryHeader do
		alias Types
		alias Types.Date

		defstruct line_number: nil,
							date: nil,
							status: :uncleared,
							code: nil,
							payee: nil,
							comment: nil

		@type t :: %__MODULE__{line_number: integer(),
													 date: Date.t(),
													 status: Types.status(),
													 code: String.t(),
													 payee: String.t(),
													 comment: String.t() }
	end

end