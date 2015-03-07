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
									 				 format: :symbol_right_with_space |
									 				 				 :symbol_right_no_space |
									 				 				 :symbol_left_with_space |
									 				 				 :symbol_left_no_space}
	end


	defmodule Date do
		defstruct year: nil,
							month: nil,
							day: nil

		@type t :: %__MODULE__{year: integer(),
										 			 month: integer(),
										 			 day: integer()}
	end


	defmodule Header do
		@moduledoc """
		Defines a transaction header.
		"""
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


	defmodule Posting do
		@moduledoc """
		Defines a posting within a transaction.
		"""
		alias Types.Amount
		alias Types.Header

		defstruct header: nil,
							line_number: nil,
							account: nil,
							amount: nil,
							comment: nil

		@type t :: %__MODULE__{header: Header.t(),
													 line_number: integer(),
													 account: [String.t()],
													 amount: Amount.t(),
													 comment: String.t()}

		@doc """
		Returns `true` if argument is a Posting; otherwise `false`.
		"""
		@spec posting?(any) :: boolean
		def posting?(%Posting{}), do: true
		def posting?(_), 					do: false
	end

end
