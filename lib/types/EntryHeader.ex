defmodule Types.EntryHeader do
	defstruct line_number: nil,
						date: nil,
						status: :uncleared,
						code: nil,
						payee: nil,
						comment: nil

	@type t :: %__MODULE__{line_number: integer(),
												 date: Date.t(),
												 status: :uncleared | :cleared,
												 code: String.t(),
												 payee: String.t(),
												 comment: String.t() }
end
