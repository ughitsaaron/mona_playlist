defmodule MonaTest do
  use ExUnit.Case
  doctest Mona

  test "greets the world" do
    assert Mona.hello() == :world
  end
end
