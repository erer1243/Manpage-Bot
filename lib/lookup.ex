defmodule ManpageBot.Lookup do
  require Logger

  # Public functions
  def man(name) do
    Logger.info("START  man #{name}")
    res = search_manpage(name, 1, true)
    Logger.info("FINISH man #{name}")
    res
  end

  def man(name, section) do
    Logger.info("START  man #{section} #{name}")
    res = search_manpage(name, section, false)
    Logger.info("FINISH man #{section} #{name}")
    res
  end

  def man_multiple(names) do
    names
    |> Enum.map(&Task.async(fn -> man(&1) end))
    |> Enum.map(&Task.await/1)
  end

  # Private functions
  defp search_manpage(name, section, continue) when section <= 9 do
    case HTTPoison.get(gz_url(name, section)) do
      {:ok, resp} ->
        case resp.status_code do
          200 ->
            {:ok, get_description(resp.body), html_url(name, section)}

          404 ->
            if continue do
              search_manpage(name, section + 1, true)
            else
              {:error, "no manual entry for #{name} in section #{section}"}
            end

          n ->
            {:error, "unhandled response status code #{n}"}
        end

      {:error, err} ->
        {:error, "HTTPoison error: #{HTTPoison.Error.message(err)}"}
    end
  end

  defp search_manpage(name, _, _), do: {:error, "manpage \"#{name}\" not found"}

  @gz_url_base Application.get_env(:manpagebot, :manpage_gz_url_base)
  @html_url_base Application.get_env(:manpagebot, :manpage_html_url_base)

  defp gz_url(name, section) do
    "#{@gz_url_base}/man#{section}/#{name}.#{section}.gz"
  end

  defp html_url(name, section) do
    "#{@html_url_base}/man#{section}/#{name}.#{section}.html"
  end

  defp get_description(gz) do
    gz
    |> String.codepoints()
    |> StreamGzip.gunzip()
    |> Enum.into("")
    |> String.split("\n")
    |> Enum.drop_while(&(not String.match?(&1, ~r/\.S[hH] DESCRIPTION/)))
    |> Enum.drop(1)
    |> Enum.take_while(&(not String.match?(&1, ~r/\.S[hH].+/)))
    |> Enum.join("\n")
  end
end
