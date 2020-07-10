defmodule OneWord.Client do
	use Nostrum.Consumer

	alias Nostrum.Api

  def start_link do
		Consumer.start_link(__MODULE__)
  end

	def handle_event({:MESSAGE_CREATE, message, _ws_state}) do
		if (!message.author.bot) do
			if OneWord.Command.handle_message(message) == :notacommand do
				OneWord.GameHandler.update_game(message.channel_id, {:add_word, message})
			end
		end

		if Enum.random(1..40) == 1, do: Api.create_reaction(message.channel_id, message.id, Enum.random(["thonk:381325006761754625", "🤔", "😂", "😭"]))
	end

	def handle_event({:READY, data, _ws_state}) do
		IO.puts("Logged in under user #{data.user.username}##{data.user.discriminator}")
		Api.update_status(:dnd, "Audio Books", 2)
	end

	def handle_event(_event), do: :noop
end
