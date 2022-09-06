defmodule Mona.Main do
  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Mona.Router,
        options: [port: port()]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Mona.Supervisor)
  end

  def main(_args) do
    :timer.sleep(:infinity)
  end

  defp port, do: 4000
end
