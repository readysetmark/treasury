defmodule Treasury do

	def load_pricedb do
		{:ok, pricedb_device} = File.open("/Users/mark/Nexus/Documents/finances/ledger/.pricedb", [:read, :utf8])
		price_list = ExParsec.parse_file(pricedb_device, JournalParser.price_db)
		File.close(pricedb_device)
		price_list
	end

end
