defmodule OneWord.Command do

	@type message :: Nostrum.Struct.Message.t()
	@type args :: any

	@callback run(message, args) :: any
	@callback help(message) :: any

	def handle_message(message) do
		with {:ok, command_name, args} <- parse_command(message),
		do: run_command(command_name, args, message)
	end

	defp parse_command(message) do
		with true <- String.starts_with?(message.content, Application.fetch_env!(:one_word, :prefix_list)),
			[name | args] <- parse_name_and_args(message.content)
			do
				{:ok, name, args}
			else
				_ -> :notacommand
			end
	end

	defp run_command("help", args, message) do
		module = OneWord.CommandList.get_command_by_name("help")
		if module != :notacommand, do: apply(module, :help, [message, args]),
		else: :notacommand
	end
	defp run_command(name, args, message) do
		module = OneWord.CommandList.get_command_by_name(name)
		if module != :notacommand, do: apply(module, :run, [message, args]),
		else: :notacommand
	end

	# Extracts the command name and args into a list, like `[name | args]`.
	defp parse_name_and_args(content) do
		content
		|> String.replace(Application.fetch_env!(:one_word, :prefix_list), "", global: false)
		|> String.split()
	end
end
