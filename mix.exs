defmodule OneWord.MixProject do
  use Mix.Project

  def project do
    [
      app: :one_word,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
			mod: {OneWord, []},
			env: [prefix_list: ["!"]],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.4"}
    ]
  end
end
