defmodule CodiscoTest do
  use ExUnit.Case
  doctest Codisco

  test "greets the world" do
    assert Codisco.hello() == :world
  end
end
