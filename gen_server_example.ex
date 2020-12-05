defmodule KeyValueStore do
  use GenServer

  def start() do
    GenServer.start(KeyValueStore, nil)
  end

  def put(pid, key, value) do
    GenServer.cast(pid, {:put, key, value})
  end

  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:put, key, value}, state) do
    {:noreply, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _, state) do
    {:reply, Map.get(state, key), state}
  end
end

# {:ok, pid} = KeyValueStore.start()
# KeyValueStore.put(pid, :some_key, :some_value)
# result = KeyValueStore.get(pid, :some_key)

# IO.inspect(result)

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
  use GenServer

  def start() do
    GenServer.start(TodoServer, nil)
  end

  def entries(pid, date) do
    GenServer.call(pid, {:entries, date})
  end

  def add_entry(pid, entry) do
    GenServer.cast(pid, {:add_entry, entry})
  end

  def update_entry(pid, entry) do
    GenServer.cast(pid, {:update_entry, entry})
  end

  def delete_entry(pid, entry_id) do
    GenServer.cast(pid, {:delete_entry, entry_id})
  end

  def init(_) do
    {:ok, TodoList.new()}
  end

  def handle_cast({:add_entry, entry}, todo_list) do
    {:noreply, TodoList.add_entry(todo_list, entry)}
  end

  def handle_cast({:update_entry, entry}, todo_list) do
    {:noreply, TodoList.update_entry(todo_list, entry)}
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    {:noreply, TodoList.delete_entry(todo_list, entry_id)}
  end

  def handle_call({:entries, date}, _, todo_list) do
    {:reply, TodoList.entries(todo_list, date), todo_list}
  end
end

{:ok, todo_server} = TodoServer.start()
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
