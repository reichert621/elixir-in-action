defmodule TodoList do
  defstruct auto_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(entries, %TodoList{}, fn entry, acc ->
      add_entry(acc, entry)
    end)
  end

  def add_entry(todo_list, entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)
    new_entries = Map.put(todo_list.entries, todo_list.auto_id, entry)

    %TodoList{todo_list | entries: new_entries, auto_id: todo_list.auto_id + 1}
  end

  def update_entry(todo_list, entry_id, updater_fn) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = %{id: ^entry_id} = updater_fn.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)

        %TodoList{todo_list | entries: new_entries}
    end
  end

  def update_entry(todo_list, %{id: entry_id} = new_entry) do
    update_entry(todo_list, entry_id, fn _ -> new_entry end)
  end

  def delete_entry(todo_list, entry_id) do
    new_entries = Map.delete(todo_list.entries, entry_id)

    %TodoList{todo_list | entries: new_entries}
  end

  def entries(todo_list, date) do
    todo_list.entries
    |> Stream.filter(fn {_, entry} -> entry.date == date end)
    |> Enum.map(fn {_, entry} -> entry end)
  end
end

defmodule TodoServer do
  def start() do
    spawn(fn -> loop(TodoList.new()) end)
  end

  def entries(todo_server, date) do
    IO.inspect("Caller PID: #{inspect(self())}")
    send(todo_server, {:entries, self(), date})

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  def add_entry(todo_server, entry),
    do: send(todo_server, {:add_entry, entry})

  def update_entry(todo_server, entry),
    do: send(todo_server, {:update_entry, entry})

  def delete_entry(todo_server, entry_id),
    do: send(todo_server, {:delete_entry, entry_id})

  defp loop(todo_list) do
    next =
      receive do
        message -> process(todo_list, message)
      end

    loop(next)
  end

  defp process(todo_list, {:add_entry, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp process(todo_list, {:update_entry, entry}),
    do: TodoList.update_entry(todo_list, entry)

  defp process(todo_list, {:delete_entry, entry_id}),
    do: TodoList.delete_entry(todo_list, entry_id)

  defp process(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end

  defp process(todo_list, invalid) do
    IO.puts("invalid request #{inspect(invalid)}")
    todo_list
  end
end

todo_server = TodoServer.start()
IO.inspect("Server PID: #{inspect(todo_server)}")

TodoServer.add_entry(
  todo_server,
  %{date: ~D[2018-12-19], title: "Dentist"}
)

TodoServer.add_entry(
  todo_server,
  %{date: ~D[2018-12-20], title: "Shopping"}
)

TodoServer.add_entry(
  todo_server,
  %{date: ~D[2018-12-19], title: "Movies"}
)

results = TodoServer.entries(todo_server, ~D[2018-12-19])
IO.inspect(results)

TodoServer.delete_entry(
  todo_server,
  1
)

TodoServer.update_entry(
  todo_server,
  %{date: ~D[2018-12-19], id: 3, title: "Watch TV"}
)

results = TodoServer.entries(todo_server, ~D[2018-12-19])
IO.inspect(results)

defmodule TodoServerV2 do
  def start() do
    spawn(fn ->
      Process.register(self(), :todo_server)

      loop(TodoList.new())
    end)
  end

  def entries(date) do
    send(:todo_server, {:entries, self(), date})

    receive do
      {:todo_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  def add_entry(entry),
    do: send(:todo_server, {:add_entry, entry})

  def update_entry(entry),
    do: send(:todo_server, {:update_entry, entry})

  def delete_entry(entry_id),
    do: send(:todo_server, {:delete_entry, entry_id})

  defp loop(todo_list) do
    next =
      receive do
        message -> process(todo_list, message)
      end

    loop(next)
  end

  defp process(todo_list, {:add_entry, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp process(todo_list, {:update_entry, entry}),
    do: TodoList.update_entry(todo_list, entry)

  defp process(todo_list, {:delete_entry, entry_id}),
    do: TodoList.delete_entry(todo_list, entry_id)

  defp process(todo_list, {:entries, caller, date}) do
    send(caller, {:todo_entries, TodoList.entries(todo_list, date)})
    todo_list
  end

  defp process(todo_list, invalid) do
    IO.puts("invalid request #{inspect(invalid)}")
    todo_list
  end
end

# TodoServerV2.start()
# Process.sleep(1000)
# TodoServerV2.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
# TodoServerV2.add_entry(%{date: ~D[2018-12-20], title: "Shopping"})
# TodoServerV2.add_entry(%{date: ~D[2018-12-19], title: "Movies"})

# results = TodoServerV2.entries(~D[2018-12-19])
# IO.inspect(results)

# TodoServerV2.delete_entry(1)
# TodoServerV2.update_entry(%{date: ~D[2018-12-19], id: 3, title: "Watch TV"})

# results = TodoServerV2.entries(~D[2018-12-19])
# IO.inspect(results)
