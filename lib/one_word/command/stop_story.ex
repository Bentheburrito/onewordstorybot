defmodule OneWord.Command.StopStory do
	@behaviour OneWord.Command

	alias Nostrum.Api

	require Logger

	@impl OneWord.Command
	def run(%{channel_id: channel_id} = message, _args) do
		with {:ok, game} <- OneWord.GameHandler.get_game(channel_id),
			:ok <- OneWord.Game.stop_game(game.pid, message.author.id)
			do
				Api.create_message(channel_id, "Game Stopped")
			else
				:already_started -> Api.create_message(channel_id, "A story is already being told.")
				:no_auth -> Api.create_message(channel_id, "Only the story-initiator (the user that typed !story) can manualy stop the story.")
				:error -> Api.create_message(channel_id, "No game in this channel.")
		end
	end

	@impl OneWord.Command
	def help(message) do
		Api.create_message(message.channel_id, "Manually stops the story being told in the channel. Usage: !stopstory")
	end
end
