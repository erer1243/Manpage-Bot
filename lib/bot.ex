defmodule ManpageBot.Bot do
  use Nostrum.Consumer
  alias Nostrum.Api

  @prefix Application.get_env(:manpagebot, :prefix)
  @help_message """
  ```
  NAME
    Manpage Bot - a Discord-based interface to
                  the Ubuntu manpage repo

  SYNOPSIS
    !man MANPAGE...
    !man SECTION MANPAGE

  DESCRIPTION
    Manpage Bot (MB for short) is a simple bot
    that looks up and parses manpages from the
    Ubuntu manpage repo.

    Given one or more MANPAGE, MB will print
    the description section of the MANPAGE(s).
    Like the regular man command, sections are
    searched in order and the first found
    manpage is shown.

    Given a SECTION and a MANPAGE, MB will
    print the MANPAGE in that SECTION (if it
    exists), instead of searching.

  AUTHOR
    Written by erer1243 #3478
  ```
  """

  def parse_and_do_search(message) do
    words = message |> String.split() |> Enum.uniq()

    if length(words) == 2 do
      num = hd(words)
      name = hd(tl(words))

      case Integer.parse(num) do
        {s, ""} when s >= 1 and s <= 9 ->
          [ManpageBot.Lookup.man(name, s)]

        {_s, _remainder} ->
          [{:error, "section must be between 1 and 9"}]

        # If there is an integer parse error,
        # we probably just have two manpage names
        _error ->
          ManpageBot.Lookup.man_multiple(words)
      end
    else
      ManpageBot.Lookup.man_multiple(words)
    end
  end

  def parse_search_results(results) do
    case results do
      [result | rest] ->
        msg =
          case result do
            {:ok, desc, url} ->
              "#{url}\n" <>
                cond do
                  String.length(desc) == 0 ->
                    "(no description found)"

                  String.length(desc) > 1800 ->
                    trimmed =
                      desc
                      |> String.codepoints()
                      |> Enum.take(1800)
                      |> Enum.into("")

                    "```#{trimmed}```... (description too long)"

                  true ->
                    "```#{desc}```"
                end

            {:error, msg} ->
              "Error: #{msg}"
          end

        [msg | parse_search_results(rest)]

      [] ->
        []
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    send = &Api.create_message(msg.channel_id, &1)

    case msg.content do
      @prefix ->
        send.("What manual page do you want? (#{@prefix} help for more info)")

      @prefix <> " " <> body ->
        if body == "help" do
          send.(@help_message)
        else
          {:ok, reply} = send.("Searching")
          results = body |> parse_and_do_search() |> parse_search_results()

          Api.edit_message(reply, content: hd(results))
          Enum.map(tl(results), send)
          # Enum.map(results, send)
        end

      _ ->
        :ignore
    end
  end

  def handle_event(_), do: :ignore
  def start_link, do: Consumer.start_link(__MODULE__, name: __MODULE__)
end
