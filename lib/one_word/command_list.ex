defmodule OneWord.CommandList do
	use Agent

	def start_link(_init_args) do
		Agent.start_link(&reg_commands/0, name: __MODULE__)
	end

	def reg_commands do
		for file <- File.ls!("./lib/one_word/command"), into: %{} do
			name = String.replace_suffix(file, ".ex", "")
			{name |> String.replace("_", ""), String.to_existing_atom("Elixir.OneWord.Command.#{name |> String.split("_") |> Enum.map(&String.capitalize/1) |> Enum.join()}")}
		end
	rescue
		e -> IO.puts "Could not register commands: #{inspect e}"
	end

	def get_command_by_name(name) do
		Agent.get(__MODULE__, &Map.get(&1, name, :notacommand))
	end

	def set_command(name, module) do
		Agent.update(__MODULE__, &Map.put(&1, name, module))
	end

	def list do
		Agent.get(__MODULE__, &(&1))
	end
end
