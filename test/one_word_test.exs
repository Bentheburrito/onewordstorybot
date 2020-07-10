defmodule OneWordTest do
  use ExUnit.Case
  doctest OneWord

  test "greets the world" do
    assert OneWord.hello() == :world
  end
end
