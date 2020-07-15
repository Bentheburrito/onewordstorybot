defmodule OneWord.Command.StartStory do
	@behaviour OneWord.Command

	alias Nostrum.Api

	require Logger

	@impl OneWord.Command
	def run(%{channel_id: channel_id} = message, _args) do
		with {:ok, game} <- OneWord.GameHandler.get_game(channel_id),
			:ok <- OneWord.Game.start_game(game.pid, message.author.id)
			do
				Api.create_message(channel_id, "Game Started")
			else
				:already_started -> Api.create_message(channel_id, "A story is already being told.")
				:no_auth -> Api.create_message(channel_id, "Only the story-initiator (the user that typed !story) can manualy start the story.")
				:error -> Api.create_message(channel_id, "No game in this channel.")
		end
	end

	@impl OneWord.Command
	def help(message) do
		Api.create_message(message.channel_id, "Manually starts the story in the current channel. Usage: !startstory")
	end
end
