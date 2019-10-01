defmodule ManpageBot.MixProject do
  use Mix.Project

  def project do
    [
      app: :manpagebot,
      version: "0.1.0",
      elixir: "~> 1.9.1",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ManpageBot.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, "~> 0.4"},
      {:httpoison, "~> 1.6.0"},
      {:stream_gzip, "~> 0.4"},

      # Earliest version that fixes this issue
      # https://github.com/benoitc/hackney/issues/591
      {:hackney, git: "https://github.com/benoitc/hackney", ref: "9c3f57807f", override: true}
    ]
  end
end
