defmodule FunRegistry do
  def start do
    Agent.start(fn -> %{} end, name: __MODULE__)
  end

  def register(module, function, callback) do
    Agent.update(__MODULE__, fn funs ->
      Map.merge(funs, %{ internal_name_for_function(module, function) => callback })
    end)
  end

  def list do
    Agent.get(__MODULE__, fn state -> state end)
  end

  def get_function(module, function) do
    Agent.get(__MODULE__, fn funs ->
      funs[internal_name_for_function(module, function)]
    end)
  end

  defp internal_name_for_function(module, function) do
    "#{module}.#{function}"
  end

  def clear! do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  def run!(module, name, args) do
    fake = get_function(module, name)

    if fake do
      apply(fake, args)
    else
      raise "Function '#{module}.#{name}' not registered"
    end
  end

  def set!(module, name, resp) when is_function(resp) do
    register(module, name, resp)
  end

  def set!(module, name, resp) do
    register(module, name, fn(_, _) -> resp end)
  end

end

