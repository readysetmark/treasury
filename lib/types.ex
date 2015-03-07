defmodule Types do

	@type status :: :uncleared | :cleared

	defmodule Symbol do
		defstruct value: nil,
							quoted: nil

		@type t :: %__MODULE__{value: String.t(), quoted: boolean()}
	end


	defmodule Amount do
		alias Decimal
		alias Types.Symbol

		defstruct qty: nil,
							symbol: nil,
							format: nil

		@type t :: %__MODULE__{qty: Decimal.t(),
									 				 symbol: Symbol.t(),
									 				 format: :symbol_right_with_space 
																	 | :symbol_right_no_space
									 								 | :symbol_left_with_space
									 								 | :symbol_left_no_space}
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


	defmodule EntryLine do
		alias Types.Amount
		alias Types.EntryHeader

		defstruct header: nil,
							line_number: nil,
							account: nil,
							amount: nil,
							comment: nil

		@type t :: %__MODULE__{header: EntryHeader.t(),
													 line_number: integer(),
													 account: [String.t()],
													 amount: Amount.t(),
													 comment: String.t()}

		@doc """
		Returns `true` if argument is an EntryLine; otherwise `false`.
		"""
		@spec entry_line?(any) :: boolean
		def entry_line?(%EntryLine{}), do: true
		def entry_line?(_), 					 do: false
	end

end
