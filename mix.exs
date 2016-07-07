defmodule SatZendeskBotEx.Mixfile do
  use Mix.Project

  def project do
    [app: :sat_zendesk_bot_ex,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [mod: {BotApplication, []}, applications: [:logger, :slack]]
  end

  defp deps do
    [
      {:slack, "~> 0.7.0"},
      {:websocket_client, git: "https://github.com/jeremyong/websocket_client"},
    ]
  end
end
