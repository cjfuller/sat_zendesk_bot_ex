defmodule SatZendeskBotEx do
  use Slack

  @zendesk_tickets "C14M6HFRP"
  @sat_monitoring "C12DQLCQ6"
  @message_fields [:fallback, :text, :pretext, :title]

  def handle_connection(slack) do
    IO.puts "Connected as #{slack.me.name}"
  end

  def handle_message(%{type: "message", channel: @zendesk_tickets, attachments: msg}, slack) do
    IO.puts ""
    IO.puts(IO.ANSI.cyan() <> "Received Zendesk report:" <> IO.ANSI.reset())
    IO.inspect(msg)
    IO.puts ""

    sat_exp = ~r/sat/i
    cb_exp = ~r/college\s?board/i

    sat_message = (
      @message_fields
      |> Enum.any?(
      fn f ->
        Enum.any?(
          msg,
          fn a ->
            a[f] && (Regex.match?(sat_exp, a[f]) || Regex.match?(cb_exp, a[f]))
          end
        )
      end))

    if sat_message do
      IO.puts(IO.ANSI.green() <> "Sending to SAT monitoring room" <> IO.ANSI.reset())
      %{
        type: "message",
        channel: @sat_monitoring,
        attachments: msg
      }
      |> JSX.encode!
      |> Slack.Sends.send_raw(slack)
    end
  end

  def handle_message(_, _), do: nil
end

defmodule BotApplication do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Supervisor.start_link(
      [supervisor(SatZendeskBotEx, [
              "~/.sat-zendesk-bot-token"
              |> Path.expand
              |> File.read!
              |> String.strip])],
      [strategy: :one_for_one, name: BotSupervisor])
  end
end
