defmodule GrpcFakeTest do
  use ExUnit.Case
  doctest GrpcFake

  test "greets the world" do
    assert GrpcFake.hello() == :world
  end
end
