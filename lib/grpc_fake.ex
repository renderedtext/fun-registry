defmodule GRPC.Fake do
  def start do
    Agent.start(fn -> %{} end, name: __MODULE__)
  end

  def add_fake(module, function, callback) do
    Agent.update(__MODULE__, fn fakes ->
      Map.merge(fakes, %{ fake_name(module, function) => callback })
    end)
  end

  def get_fake(module, function) do
    Agent.get(__MODULE__, fn fakes ->
      fakes[fake_name(module, function)]
    end)
  end

  def fake_name(module, function) do
    "#{module}.#{function}"
  end

  def clear_fakes! do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  defmacro __using__(options) do
    quote do
      def fake!(name, resp) when is_function(resp) do
        GRPC.Fake.add_fake(__MODULE__, name, resp)
      end

      def fake!(name, resp) do
        GRPC.Fake.add_fake(__MODULE__, name, fn(_, _) -> resp end)
      end

      def run_fake(name, args) do
        fake = GRPC.Fake.get_fake(__MODULE__, name)

        if fake do
          apply(fake, args)
        else
          raise "Fake #{name} not defined for #{__MODULE__}"
        end
      end
    end
  end
end

