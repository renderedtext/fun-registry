# FunRegistry - Function Registry

A dynamic function registry, useful for implementing processes that can be
modified during their lifetime.

An example use case is the creation of fake GRPC that emulates remote servers.
This is useful in development and test environments.

## Installation

Add the following to your mixfile:

```elixir
def deps do
  [
    {:fun_registry, github: "renderedtext/fun-registry", only: [:dev, :test]}
  ]
end
```

## Example usage for creating fake GRPC servers

First, we will create a fake server that emulates a remote Calculator service:

``` elixir
defmodule CalculatorService do
  use GRPC.Server, service: Calculator.Service

  def add(req, stream) do
    # instead of an implementation, we will relly on the FunRegistry
    # to fetch and run a function

    FunRegistry.run(__MODULE__, :add, [req, stream])
  end
end

GRPC.Server.start(CalculatorService, 50051)
```

Let's connect to the calculator service and invoke some rpc methods:

``` elixir
def calculate_remotly(a, b) do
  #
  # in dev and test this is set to "localhost:50051"
  # in prod we will connect to a real server
  #
  endpoint = Application.get_env(:my_app, :calculator_endpoint)

  {:ok, channel} = GRPC.Server.connect(endpoint)

  req = Calculator.AddRequest.new(a: 12, b: 13)

  {:ok, res} = Calculator.Stub.add(req)

  res.result
end
```

Now, we can use the function registry to simulate the behaviour of the remote
server:

``` elixir
setup do
  FunRegistry.clear!
end

test "calculate-remotly is able to communicate with remote servers" do
  # first, we will stub the behaviour of the server
  FunRegistry.set!(CalculatorService, :add, fn(req, _) ->
    Calculator.AddResponse.new(result: req.a + req.b)
  end)

  assert calculate_remotly(1, 2) == 10
end

test "calculate-remotly is able to communicate with remote servers stubbed version" do
  # instead of functions, we can set a stubbed response directly
  FunRegistry.set!(CalculatorService, :add, Calculator.AddResponse.new(result: 10))

  assert calculate_remotly(1, 2) == 10
end

test "calculate-remotly passes the correct data to the remote service" do
  # we will store the values in an agent
  {:ok, agent} = Agent.new(fn -> nil end)

  # instead of functions, we can set a stubbed response directly
  FunRegistry.set!(CalculatorService, :add, fun(req, _) ->
    Agent.update(agent, fn state -> {req.a, req.b} end)
  end)

  # execute the remote call
  calculate_remotly(1, 2) == 10

  # fetch the data that was received by the remote server
  values = Agent.get(agent, pid, fn s -> s end)

  # make sure that the remote server got the correct info
  assert values == {1, 2}
end

test "calculate service is too slow" do
  # first, we will stub the behaviour of the server
  FunRegistry.set!(CalculatorService, :add, fun(_, _) ->
    :timer.sleep(5000)
  end)

  assert_raise fn -> calculate_remotly(1, 2) end)
end

test "calculate service is broken" do
  # first, we will stub the behaviour of the server
  FunRegistry.set!(CalculatorService, :add, fun(_, _) ->
    raise "I don't feel well"
  end)

  assert_raise fn -> calculate_remotly(1, 2) end)
end
```

