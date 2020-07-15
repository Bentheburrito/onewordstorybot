defmodule OneWord.GameHandler do
	use GenServer

	# alias OneWord.Game

	require Logger

	alias OneWord.Game

	@type game_id :: Nostrum.Snowflake.t()

	# ~Client~
	def start_link(_init_arg) do
		GenServer.start_link(__MODULE__, [], name: __MODULE__)
	end

	def new_game(game_id, data) when is_number(game_id) do
		GenServer.call(__MODULE__, {:new, game_id, data})
	end

	def get_game(game_id) do
		GenServer.call(__MODULE__, {:get, game_id})
	end

	def update_game(game_id, data) do
		GenServer.call(__MODULE__, {:update, game_id, data})
	end

	def stop_game(game_id, author_id) do
		case get_game(game_id) do
			{:ok, %{pid: pid}} -> Game.stop_game(pid, author_id)
			:error -> :no_game
		end
	end

	def game_active?(game_id) do
		GenServer.call(__MODULE__, {:game_active?, game_id})
	end

	# ~Server~
	def init(_arg) do
		{:ok, {%{}, %{}}} # A map of games, where the key is the game_id
	end

	def handle_call({:new, game_id, init_state}, _from, {refs, games}) do
		if Map.has_key?(games, game_id) do
			{:reply, :already_exists, {refs, games}}
		else
			{:ok, pid} = DynamicSupervisor.start_child(GameSupervisor, Supervisor.child_spec({OneWord.Game, init_state}, id: game_id))

			ref = Process.monitor(pid)
			refs = Map.put(refs, ref, game_id)

			game_state = Map.put(init_state, :pid, pid)
			games = Map.put(games, game_id, game_state)

			{:reply, {:ok, game_state}, {refs, games}}
		end
	end

	def handle_call({:get, game_id}, _from, {refs, games}) do
		{:reply, Map.fetch(games, game_id), {refs, games}}
	end

	# game handler tracks state so it can be restored if the game process were to crash.
	def handle_call({:update, game_id, data}, _from, {refs, games}) do
		game = Map.fetch!(games, game_id)
		games = Map.put(games, game_id, Map.merge(game, data))
		{:reply, :ok, {refs, games}}
	end

	def handle_call({:game_active?, game_id}, _from, {refs, games}) do
		{:reply, Map.has_key?(games, game_id), {refs, games}}
	end

	def handle_info({:DOWN, ref, :process, _pid, :normal}, {refs, games}) do
		{game_id, refs} = Map.pop(refs, ref)
		games = Map.delete(games, game_id)
		{:noreply, {games, refs}}
	end

	# If a game crashes, restart it with its last known "good" state, and update the refs.
	def handle_info({:DOWN, ref, :process, _pid, _reason}, {refs, games}) do

		{game_id, refs} = Map.pop(refs, ref)
		game_state = Map.get(games, game_id)

		{:ok, pid} = DynamicSupervisor.start_child(GameSupervisor, Supervisor.child_spec({OneWord.Game, Map.delete(game_state, :pid)}, id: game_id))

		ref = Process.monitor(pid)
		refs = Map.put(refs, ref, game_id)

		game_state = Map.put(game_state, :pid, pid)
		games = Map.put(games, game_id, game_state)

		{:noreply, {refs, games}}
	end

	def handle_info(_msg, {refs, games}) do
		{:noreply, {refs, games}}
	end
end
