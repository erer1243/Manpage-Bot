defmodule ManpageBot.Lookup do
  # Public functions
  def man(name) do
    search_manpage(name, 1, true)
  end

  def man(name, section) do
    search_manpage(name, section, false)
  end

  # Private functions
  defp search_manpage(name, section, continue) when section <= 9 do
    case HTTPoison.get(gz_url(name, section)) do
      {:ok, resp} ->
        case resp.status_code do
          200 ->
            {:ok, "description here", html_url(name, section)}

          404 ->
            if continue do
              search_manpage(name, section + 1, true)
            else
              {:error, "manpage \"#{name}\" not found in section #{section}"}
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
    |> Enum.take(1500)
    |> Enum.into("")
  end
end
