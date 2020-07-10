defmodule OneWord.Command.Say do
	@behaviour OneWord.Command

	alias Nostrum.Api

	@impl OneWord.Command
	def run(message, args) do
		case Api.delete_message(message) do
			{:error, e} -> IO.puts(e.response.message)
			_ -> nil
		end
		Api.create_message(message.channel_id, Enum.join(args, " "))
	end

	@impl OneWord.Command
	def help(_message), do: nil
end
