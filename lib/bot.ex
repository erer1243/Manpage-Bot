defmodule ManpageBot.Bot do
  use Nostrum.Consumer
  alias Nostrum.Api

  @prefix Application.get_env(:manpagebot, :prefix)
  @help_message """
  ```
  NAME
    Manpage Bot - a Discord-based interface to the
                  on-line reference manuals

  SYNOPSIS
    !man MANPAGE...

  DESCRIPTION
    Manpage Bot is a simple bot that looks up the
    given manpages on http://man.he.net and returns
    the links.

  AUTHOR
    Written by erer1243 #3478
  ```
  """

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    send = &Api.create_message(msg.channel_id, &1)

    case msg.content do
      @prefix ->
        send.("What manual page do you want? (#{@prefix} help for more info)")

      @prefix <> " " <> body ->
        if body == "help" do
          send.(@help_message)
        else
          send.("lookup #{body}")
        end

      _ ->
        :ignore
    end
  end

  def handle_event(_), do: :ignore
  def start_link, do: Consumer.start_link(__MODULE__)
end
