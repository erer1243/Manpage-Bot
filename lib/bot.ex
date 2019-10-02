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

  @doc """
  Given a message from a user (everything after the command prefix),
  this parses the message and then uses ManpageBot.Lookup to search
  for relavant manpages.

  Currently, the only parsing done is checking whether a section number
  is provided for the given search.

  Returns a list of results where a result is either
  {:ok, <manpage description>, <manpage html url>} or
  {:error, <error message string>}
  """
  def parse_and_do_search(message) do
    words = message |> String.split() |> Enum.uniq()

    # Check if a section number is provided
    if length(words) == 2 do
      num = hd(words)
      name = hd(tl(words))

      case Integer.parse(num) do
        # Have a clear number
        {s, ""} when s >= 1 and s <= 9 ->
          [ManpageBot.Lookup.man(name, s)]

        # Have a clear number but it's too big
        {_s, ""} ->
          [{:error, "section must be between 1 and 9"}]

        # No clear number - probably just two manpages to be looked up
        _ ->
          ManpageBot.Lookup.man_multiple(words)
      end
    else
      # If there are 1 or 3+ words, look them all up
      ManpageBot.Lookup.man_multiple(words)
    end
  end

  @doc """
  Given a list of results from parse_and_do_search, this parses those reuslts
  and generates a message to be given back to the user for each result.

  Returns a list of strings, the messages generated.
  """
  def parse_search_results(results) do
    case results do
      [] ->
        []

      [result | rest] ->
        msg =
          case result do
            # Searched manpage was found
            {:ok, desc, url} ->
              "#{url}\n" <>
                cond do
                  # Add a message if no description was found
                  String.length(desc) == 0 ->
                    "(no description found)"

                  # Trim the manpage description if needed
                  String.length(desc) > 1700 ->
                    "```#{String.slice(desc, 0..1700)}\n... (description too long)```"

                  # Have an okay description, no special treatment
                  true ->
                    "```#{desc}```"
                end

            # Searched manpage was not found (or other errors)
            {:error, msg} ->
              "Error: #{msg}"
          end

        [msg | parse_search_results(rest)]
    end
  end

  @doc """
  Nostrum callback implementation that handles new messages.
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
          {:ok, reply} = send.("Searching")
          results = body |> parse_and_do_search() |> parse_search_results()

          # Edit the "searching" message for the first result
          Api.edit_message(reply, content: hd(results))
          # Create a new message for any remaining results
          Enum.map(tl(results), send)
        end

      _ ->
        :ignore
    end
  end

  def handle_event(_), do: :ignore
  def start_link, do: Consumer.start_link(__MODULE__, name: __MODULE__)
end
