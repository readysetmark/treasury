defmodule Types do

	@type status :: :uncleared | :cleared

	defmodule Symbol do
		defstruct format: nil,
							symbol: nil

		@type t :: %__MODULE__{format: :quoted | :unquoted,
													 symbol: String.t()}
	end


	defmodule Amount do
		alias Decimal
		alias Types.Symbol

		defstruct format: nil,
							qty: nil,
							symbol: nil

		@type t :: %__MODULE__{format: :symbol_right_with_space 
																	 | :symbol_right_no_space
									 								 | :symbol_left_with_space
									 								 | :symbol_left_no_space,
									 				 qty: Decimal.t(),
									 				 symbol: Symbol.t()}
	end


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
													 comment: String.t()}
	end

end