defmodule OneWord.Command.Story do
	@behaviour OneWord.Command

	@player_wait_time 10_000

	alias Nostrum.Api
	alias OneWord.GameHandler

	require Logger

	def run(%{channel_id: channel_id} = message, args) do
		cond do
			GameHandler.game_active?(channel_id) ->
				Api.create_message(channel_id, "This channel has a game in progress!")
			args == [] ->
				start_story(message, "One Word Story")
			true ->
				start_story(message, Enum.join(args, " "))
		end
	end

	defp start_story(%{channel_id: channel_id} = message, title) do

		with task <- Task.async(fn -> gather_players(message.channel_id) end),
			:ok <- register_game(message, title, task.pid),
			{:ok, users} <- Task.await(task, :infinity)
		do
			game_embed = OneWord.Game.story_embed(title, "Waiting for first word...", users)
			{:ok, game_embed_message} = Api.create_message(channel_id, embed: game_embed)
			GameHandler.update_game(channel_id, {:update_state, %{users: users, user_turn_queue: users, embed_message_id: game_embed_message.id, setup_pid: nil}})
		else
			:not_enough_players ->
				GameHandler.stop_game(channel_id, message.author.id)
				Api.create_message(channel_id, "Not enough players signed up. Use !story to try again.")
			:game_in_progress ->
				Api.create_message(channel_id, "A game is already in progress in this channel!")
			%Nostrum.Error.ApiError{} = e ->
				Api.create_message(channel_id, "API Error: #{inspect e}")
				Logger.error(e)
			e ->
				Api.create_message(channel_id, "Error: #{inspect e}")
				Logger.error(e)
		end
	end

	defp gather_players(channel_id) do

		{:ok, participation_msg} = Api.create_message(channel_id, "A new one-word story is starting! React to this message with :thumbsup: within 2 minutes to participate! (The story-initiator can manually start by sending \"!startstory\")")
		Api.create_reaction(channel_id, participation_msg.id, "👍")

		receive do
			:start -> get_reactions(channel_id, participation_msg.id)
		after
			@player_wait_time -> get_reactions(channel_id, participation_msg.id)
		end
	end

	defp get_reactions(channel_id, message_id) do
		_ = Api.delete_own_reaction(channel_id, message_id, "👍")
		{:ok, users} = Api.get_reactions(channel_id, message_id, "👍")

		if length(users) < 2 do
			:not_enough_players
		else
			# GameHandler.update_game(channel_id, {:add_players, users})
			{:ok, users}
		end
	end

	defp register_game(%{channel_id: channel_id, author: author}, title, setup_pid) do
		GameHandler.new_game(channel_id,
			%{
				game_id: channel_id,
				setup_pid: setup_pid,
				author_id: author.id,
				users: [],
				user_turn_queue: [],
				embed_message_id: nil,
				title: title,
				story: "",
				end_keywords: ["the end"],
				options: []
			}
		)
	end

	def help(message) do
		Api.create_message(message.channel_id, "**!story [story title]**\n<> = one word argument, \"\" = multi-word argument, [] = optional argument")
	end
end
