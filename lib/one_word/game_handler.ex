defmodule OneWord.GameHandler do
	use GenServer

	alias OneWord.Game

	@type game_id :: Nostrum.Snowflake.t()

	# ~Client~
	def start_link(_init_arg) do
		GenServer.start_link(__MODULE__, [], name: __MODULE__)
	end

	def new_game(game_id, data) when is_number(game_id) do
		GenServer.call(__MODULE__, {:new_game, game_id, data})
	end

	def update_game(game_id, data) do
		GenServer.call(__MODULE__, {:update_game, game_id, data})
	end

	def stop_game(game_id, author_id) do
		GenServer.call(__MODULE__, {:stop_game, game_id, author_id})
	end

	def game_active?(game_id) do
		GenServer.call(__MODULE__, {:game_active?, game_id})
	end

	# ~Server~
	def init(_arg) do
		{:ok, %{}} # A map of games, where the key is the game_id
	end

	def handle_call({:new_game, game_id, data}, _from, games) do
		if Map.has_key?(games, game_id) do
			{:reply, :game_in_progress, games}
		else
			{:ok, pid} = DynamicSupervisor.start_child(GameSupervisor, Supervisor.child_spec({OneWord.Game, data}, id: game_id))
			Process.monitor(pid)
			new_games = Map.put(games, game_id, Map.put(data, :pid, pid))
			{:reply, :ok, new_games}
		end
	end

	# game handler tracks state so it can be restored if the game process were to crash.
	def handle_call({:update_game, game_id, data}, _from, games) do
		with {:ok, game} <- Map.fetch(games, game_id),
			{:ok, new_game} <- Game.update(game.pid, data)
			do
				new_games = Map.put(games, game_id, Map.merge(game, new_game))
				{:reply, :ok, new_games}
			else
				:game_ended -> {:reply, :game_ended, Map.delete(games, game_id)}
				:error -> {:reply, :no_game, games}
				error -> {:reply, error, games}
			end
	end

	def handle_call({:stop_game, game_id, author_id}, _from, games) do
		with {:ok, game} <- Map.fetch(games, game_id),
			:game_ended <- Game.stop_game(game.pid, author_id)
			do
				new_games = Map.delete(games, game_id)
				{:reply, :ok, new_games}
			else
				:error -> {:reply, :no_game, games}
				reason -> {:reply, reason, games}
			end
	end

	def handle_call({:game_active?, game_id}, _from, games) do
		{:reply, Map.has_key?(games, game_id), games}
	end

	def handle_info({:DOWN, _ref, :process, _pid, reason}, games) do
		IO.inspect reason
		{:noreply, games}
	end

	def handle_info(_msg, games) do
		{:noreply, games}
	end
end
