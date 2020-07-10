defmodule OneWord.Command.StopStory do
	@behaviour OneWord.Command

	alias Nostrum.Api

	require Logger

	@impl OneWord.Command
	def run(%{channel_id: channel_id} = message, _args) do
		case OneWord.GameHandler.stop_game(channel_id, message.author.id) do
			:ok -> nil
			:no_game -> Api.create_message(channel_id, "There is no active game in this channel.")
			:no_auth -> Api.create_message(channel_id, "Only the story-initiator (the user that typed !story) can manualy stop the story.")
			e ->
				Api.create_message(channel_id, "Could not stop game - Error reason: #{e}")
				Logger.error("Could not stop game - Error reason: #{e}")
		end
	end

	@impl OneWord.Command
	def help(message) do
		Api.create_message(message.channel_id, "!stopstory")
	end
end
