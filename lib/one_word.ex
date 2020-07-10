defmodule OneWord do
	use Application

	# Application Entry Point
	@impl true
	def start(_type, _args) do
		OneWord.Supervisor.start_link(name: BotSupervisor)
	end
end
