defmodule OneWord.Game do
	use GenServer

	alias Nostrum.Api
	alias Nostrum.Struct.Embed
	alias Nostrum.Struct.User
	alias OneWord.GameHandler

	# ~Client~
	def start_link(config) do
		GenServer.start_link(__MODULE__, config)
	end

	def add_word(game_pid, %Nostrum.Struct.Message{} = message) when is_pid(game_pid) do
		case GenServer.call(game_pid, {:add_word, message}) do
			{:ok, updated} ->
				GameHandler.update_game(updated.game_id, updated)
				updated
			error ->
				{:error, error}
		end
	end

	### Won't need this unless we need players added mid-game.
	# def update(game_pid, {:add_players, _new_users} = data) when is_pid(game_pid) do
	# 	GenServer.call(game_pid, data)
	# end

	def update_state(game_pid, state) when is_pid(game_pid) and is_map(state) do
		case GenServer.call(game_pid, {:update_state, state}) do
			{:ok, updated} ->
				GameHandler.update_game(updated.game_id, updated)
				updated
			error ->
				{:error, error}
		end
	end

	def start_game(game_pid, author_id) when is_pid(game_pid) do
		GenServer.call(game_pid, {:start_game, author_id})
	end

	def stop_game(game_pid, author_id) when is_pid(game_pid) do
		GenServer.call(game_pid, {:end_game, author_id})
	end

	def story_embed(title, description, users) do
		%Embed{}
		|> Embed.put_author("Story by #{Enum.map(users, &Map.get(&1, :username)) |> Enum.join(", ")}", nil, List.first(users) |> User.avatar_url())
		|> Embed.put_title("#{title} | #{List.first(users).username}'s turn")
		|> Embed.put_description(String.length(description) > 2048 && ("..." <> String.slice(description, String.length(description) - 2045, 2045)) || description)
		|> Embed.put_color(0x2a94f7)
		|> Embed.put_footer("The story ends when two players type \"the end\", or the story-initiator types \"!stopstory\".", Nostrum.Cache.Me.get() |> User.avatar_url())
	end

	# ~Server~
	def init(config) do
		{:ok, config}
	end

	def handle_call({:add_word, %{content: new_content} = message}, _from, %{game_id: game_id, embed_message_id: message_id} = game_info) do
		with :ok <- validate_new_content(message, game_info),
			{:ok, story} <- Map.fetch(game_info, :story),
			{joiner, double_quotes} <- join_punctuation(new_content, game_info.double_quotes)
			do
				new_story = String.trim("#{story}#{joiner}#{new_content}")
				new_game_info = game_info |> Map.put(:story, new_story) |> Map.put(:double_quotes, double_quotes) |> Map.update!(:users, fn [first | rest] -> rest ++ [first] end)

				Api.delete_message(message)
				if String.contains?(strip_grammar(new_story), game_info.end_keywords) do
					end_game(game_id, new_game_info)
				else
					Api.edit_message(game_id, message_id, embed: story_embed(game_info.title, new_story, new_game_info.users))
					{:reply, {:ok, new_game_info}, new_game_info}
				end
			else
				:invalid ->
					Api.delete_message(message)
					{:reply, :invalid, game_info}
				:error ->
					{:reply, :no_story, game_info}
			end
	end

	def handle_call({:update_state, new_state}, _from, game_info) do
		new_game_info = Map.merge(game_info, new_state)
		{:reply, {:ok, new_game_info}, new_game_info}
	end

	def handle_call({:start_game, _author_id}, _from, %{setup_pid: nil} = game_info), do: {:reply, :already_started, game_info}
	def handle_call({:start_game, author_id}, _from, %{setup_pid: setup_pid} = game_info) do
		if game_info.author_id == author_id do
			send(setup_pid, :start)
			{:reply, :ok, game_info}
		else
			{:reply, :no_auth, game_info}
		end
	end

	def handle_call({:end_game, author_id}, _from, %{game_id: game_id} = game_info) do
		if game_info.author_id == author_id do
			end_game(game_id, game_info)
		else
			{:reply, :no_auth, game_info}
		end
	end

	# def handle_call({:add_players, new_users}, _from, game_info) do
	# 	with {:ok, users} <- Map.fetch(game_info, :users) do
	# 		new_game_info = Map.put(game_info, :users, users ++ new_users)

	# 		{:reply, {:ok, new_game_info}, new_game_info}
	# 	else
	# 		:error -> {:reply, :error, game_info}
	# 	end
	# end

	defp end_game(game_id, latest_state) do
		if latest_state.story != "", do: Api.create_message(game_id, "**#{latest_state.title}** by #{Enum.map(latest_state.users, &Map.get(&1, :username)) |> Enum.join(", ")}\n#{latest_state.story}")
		if latest_state.embed_message_id != nil, do: Api.delete_message(game_id, latest_state.embed_message_id)
		if latest_state.setup_pid != nil, do: Process.exit(latest_state.setup_pid, :normal)
		{:stop, :normal, :ok, latest_state}
	end

	defp validate_new_content(%{content: new_content, author: author}, game_info) do
		if game_info.setup_pid == nil and
		(new_content |> strip_grammar() |> String.trim() |> String.contains?(" ") == false) and
		((:no_order in game_info.options and Enum.any?(game_info.users, fn user -> user.id == author.id end) == true) or List.first(game_info.users).id == author.id),
			do: :ok,
			else:	:invalid
	end

	defp strip_grammar(string) do
		string |> String.downcase() |> String.replace(~r/[!?.,:;'"]/, "")
	end

	defp join_punctuation(content, double_quotes) do

		joiner = (String.starts_with?(content, ["!", "?", ",", ".", ":", ";"]) or (String.starts_with?(content, "\"") and rem(double_quotes, 2) == 1)) && "" || " "
		new_double_quotes = (String.graphemes(content) |> Enum.reduce(0, &(&1 == "\"" && &2 + 1 || &2))) + double_quotes

		{joiner, new_double_quotes}
	end
end
