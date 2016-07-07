defmodule SatZendeskBotEx do
  use Slack

  @zendesk_tickets "C14M6HFRP"
  @sat_monitoring "C12DQLCQ6"
  @message_fields [:fallback, :text, :pretext, :title]
  @token (
    "~/.sat-zendesk-bot-token"
    |> Path.expand
    |> File.read!
    |> String.strip)

  def token, do: @token

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
      send_sat_message(msg, slack)
    end
  end

  def handle_message(_, _), do: nil

  def reformat_attachment(att = %{service_icon: icon, service_name: name}) do
    att
    |> Map.drop([:service_icon, :service_name])
    |> Map.merge(%{footer_icon: icon, footer: name})
  end

  def send_sat_message(attachments, slack) do
      IO.puts(IO.ANSI.green() <> "Sending to SAT monitoring room" <> IO.ANSI.reset())

      Slack.Web.Chat.post_message(
        @sat_monitoring, "",
        %{
          as_user: false,
          username: "Zendesk Zebra",
          token: @token,
          attachments: attachments |> Enum.map(&reformat_attachment/1) |> JSX.encode!,
        })
  end

  def send_sat_text(text, slack) do
    %{
      type: "message",
      channel: @sat_monitoring,
      text: text,
    }
    |> JSX.encode!
    |> Slack.Sends.send_raw(slack)
  end

  def handle_info({:sat, attachments}, slack), do: send_sat_message(attachments, slack)
  def handle_info({:sat_text, text}, slack), do: send_sat_text(text, slack)

end

defmodule BotApplication do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    Supervisor.start_link(
      [supervisor(SatZendeskBotEx, [SatZendeskBotEx.token()])],
      [strategy: :one_for_one, name: BotSupervisor])
  end
end
