defmodule OneWord.Command.Say do
	@behaviour OneWord.Command

	alias Nostrum.Api

	@impl OneWord.Command
	def run(message, args) do
		if message.author.id == 254728052070678529 do
			case Api.delete_message(message) do
				{:error, e} -> IO.puts(e.response.message)
				_ -> nil
			end
			Api.create_message(message.channel_id, Enum.join(args, " "))
		end
	end

	@impl OneWord.Command
	def help(_message), do: nil
end
