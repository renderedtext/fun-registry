# GRPC.Fake

Utility to set up fake GRPC servers and stub their responses.

## Installation

```elixir
def deps do
  [
    {:grpc_fake, github: "renderedtext/grpc-fake"}
  ]
end
```

## Usage

##### 1. Create a GRPC server from a servis definition

``` elixir
defmodule Fake.CalcServer do
  use GRPC.Server, service: Calc.Service
  use GRPC.Fake

  def add(req, stream), do: run_fake(:hello, [req, stream])
end
```

##### 2. Start the fake server and the fake services

``` elixir
{:ok, _} = GRPC.Fake.start
{:ok, _, _ } = GRPC.Server.start(Fake.HelloServer, 50051)
```

##### 3. Use the fake in the tests to stub the answers

``` elixir
# code that needs testing

def calculate(a, b) do
  req = Calc.Request.new(a: a, b: b)

  {:ok, channel} = GRPC.Server.connect("localhost:50051")
  {:ok, res}     = Calc.Service.Stub.add(req)

  res
end
```

``` elixir
# tests

setup do
  GRPC.Fake.clear_fakes!
end

test "calculate with dummy response" do
  Fake.HelloServer.fake!(:hello, Calc.Reponse.new(result: 90))

  assert calculate(1, 2) == 90
end

test "calculate with fake that calculates the anwer" do
  Fake.HelloServer.fake!(:hello, fun(req, res) ->
    req.a + req.b
  end)

  assert calculate(1, 2) == 3
end

test "calculate with broken remote server" do
  Fake.HelloServer.fake!(:hello, fun(req, res) ->
    :timer.sleep(50000)
  end)

  assert_raise fn -> calculate(1, 2) end
end
```
