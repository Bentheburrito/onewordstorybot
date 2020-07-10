defmodule OneWord.Command.StartStory do
	@behaviour OneWord.Command

	alias Nostrum.Api

	require Logger

	@impl OneWord.Command
	def run(%{channel_id: channel_id} = message, _args) do
		case OneWord.GameHandler.update_game(channel_id, {:start_game, message.author.id}) do
			:ok -> nil
			:already_started -> Api.create_message(channel_id, "A story is already being told.")
			:no_auth -> Api.create_message(channel_id, "Only the story-initiator (the user that typed !story) can manualy start the story.")
		end
	end

	@impl OneWord.Command
	def help(message) do
		Api.create_message(message.channel_id, "!startstory")
	end
end
