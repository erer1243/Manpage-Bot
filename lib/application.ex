defmodule ManpageBot.Application do
  use Application

  def start(_, _) do
    Supervisor.start_link([ManpageBot.Bot], strategy: :one_for_one)
  end
end
