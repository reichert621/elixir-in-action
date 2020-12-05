defmodule Todo.Server do
  # use GenServer

  # def start(name) do
  #   IO.inspect("Starting server for #{inspect(name)}.")

  #   GenServer.start(Todo.Server, name)
  # end

  # def start_link(name) do
  #   IO.inspect("Starting server for #{inspect(name)}.")

  #   GenServer.start_link(Todo.Server, name)
  # end

  use GenServer, restart: :temporary

  def start_link(name) do
    IO.inspect("Starting server for #{inspect(name)}.")

    GenServer.start_link(Todo.Server, name, name: via_tuple(name))
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

  def init(name) do
    {:ok, {name, Todo.Database.get(name) || Todo.List.new()}}
  end

  def handle_cast({:add_entry, entry}, {name, todo_list}) do
    updated_todo_list = Todo.List.add_entry(todo_list, entry)
    Todo.Database.store(name, updated_todo_list)

    {:noreply, {name, updated_todo_list}}
  end

  def handle_cast({:update_entry, entry}, {name, todo_list}) do
    updated_todo_list = Todo.List.update_entry(todo_list, entry)
    Todo.Database.store(name, updated_todo_list)

    {:noreply, {name, updated_todo_list}}
  end

  def handle_cast({:delete_entry, entry_id}, {name, todo_list}) do
    updated_todo_list = Todo.List.delete_entry(todo_list, entry_id)
    Todo.Database.store(name, updated_todo_list)

    {:noreply, {name, updated_todo_list}}
  end

  def handle_call({:entries, date}, _, {name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {name, todo_list}}
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end
end
