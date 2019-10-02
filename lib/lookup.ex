defmodule ManpageBot.Lookup do
  require Logger

  # Public functions
  def man(name), do: search_manpage(name, 1, true)
  def man(name, section), do: search_manpage(name, section, false)

  def man_multiple(names) do
    names
    |> Enum.map(&Task.async(fn -> man(&1) end))
    |> Task.yield_many(8000)
    # Read about what Task.yield_many may return:
    # https://hexdocs.pm/elixir/Task.html#yield_many/2
    |> Enum.map(fn {task, result} ->
      Task.shutdown(task, :brutal_kill)

      case result do
        nil -> {:error, "timeout"}
        {:exit, reason} -> {:error, "Task error #{reason}"}
        {:ok, good_res} -> good_res
      end
    end)
  end

  # Private functions
  defp search_manpage(name, section, continue) when section <= 9 do
    case HTTPoison.get(gz_url(name, section)) do
      {:ok, resp} ->
        case resp.status_code do
          200 ->
            html = html_url(name, section)

            case get_description(resp.body) do
              {:ok, desc} ->
                {:ok, desc, html}

              {:error, err} ->
                {:error, "manpage at #{html} but description parsing failed because: #{err}"}
            end

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

  @doc """
  Given the gzipped manpage from the remote source,
  gunzip and parse it.

  returns a result which is either
  {:ok, <description>}
  {:error, <error message>}
  """
  defp get_description(gz) do
    raw = gz |> String.codepoints() |> StreamGzip.gunzip()
    nlines = raw |> Enum.into("") |> String.split("\n") |> length

    # Porcelain can't close stdin, so the command must be made to expect one line
    # https://github.com/alco/porcelain/issues/37
    # https://hexdocs.pm/porcelain/Porcelain.Driver.Basic.html
    # Potential BUG: nlines-1 prevents the last line from being read.
    # If the last line pertains to the description, it'll be left out.
    # It seems like the description would never include the last line, though.
    result =
      Porcelain.exec("bash", ["-c", "head -n#{nlines - 1} | man -P cat -l -"], in: raw)

    if result.status != 0 do
      {:error, "Porcelain error: #{result.err}"}
    else
      description_lines =
        result.out
        |> String.split("\n")
        |> Enum.drop_while(&(&1 != "DESCRIPTION"))
        |> Enum.drop(1)
        |> Enum.take_while(&(not String.match?(&1, ~r/^[A-Z][A-Z\s]+$/)))

      indent_len =
        description_lines
        |> Enum.filter(&(String.length(&1) > 0))
        |> Enum.map(&String.codepoints/1)
        |> Enum.map(&Enum.take_while(&1, fn c -> c == " " end))
        |> Enum.map(&length/1)
        |> Enum.min(fn -> 0 end)

      description =
        description_lines
        |> Enum.map(&String.slice(&1, indent_len..-1))
        |> Enum.join("\n")

      {:ok, description}
    end
  end
end
