defmodule DoxirTest do
  use ExUnit.Case
  doctest Doxir

  test "greets the world" do
    assert Doxir.hello() == :world
  end
end
