defmodule Calculator do
  def start() do
    spawn(fn ->
      current = 0
      loop(current)
    end)
  end

  def add(pid, num), do: send(pid, {:add, num})
  def sub(pid, num), do: send(pid, {:sub, num})
  def mul(pid, num), do: send(pid, {:mul, num})
  def div(pid, num), do: send(pid, {:div, num})

  def value(pid) do
    send(pid, {:value, self()})

    receive do
      {:response, value} -> value
    end
  end

  defp loop(current) do
    next =
      receive do
        message -> process(current, message)
      end

    loop(next)
  end

  defp process(current, {:add, value}), do: current + value
  defp process(current, {:sub, value}), do: current - value
  defp process(current, {:mul, value}), do: current * value
  defp process(current, {:div, value}), do: current / value

  defp process(current, {:value, caller}) do
    send(caller, {:response, current})

    current
  end

  defp process(current, invalid) do
    IO.puts("invalid request #{inspect(invalid)}")

    current
  end
end
