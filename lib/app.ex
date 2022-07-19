defmodule Mona.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Mona.Router, port: port()}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mona.Supervisor)
  end

  def main(__args) do
    IO.puts("Starting server")

    case :os.type() do
      {:unix, :darwin} -> {"open", ["http://localhost:4000"]}
    end

    :timer.sleep(:infinity)
  end

  defp port, do: 4000
end
