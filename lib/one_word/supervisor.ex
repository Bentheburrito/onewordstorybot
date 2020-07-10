defmodule OneWord.Supervisor do
	use Supervisor

	def start_link(opts) do
		Supervisor.start_link(__MODULE__, :ok, opts)
	end

	@impl true
	def init(:ok) do
		children = [
			{DynamicSupervisor, name: GameSupervisor, strategy: :one_for_one},
			OneWord.GameHandler,
			OneWord.CommandList,
			{OneWord.Client, name: OneWord.Client}
		]

		Supervisor.init(children, strategy: :one_for_one)
	end
end
