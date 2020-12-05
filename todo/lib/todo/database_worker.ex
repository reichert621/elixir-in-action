defmodule Todo.DatabaseWorker do
  use GenServer

  # def start(db_folder) do
  #   IO.inspect("Starting database worker.")

  #   GenServer.start(__MODULE__, db_folder)
  # end

  def start_link({db_folder, worker_id}) do
    IO.inspect("Starting database worker #{worker_id}.")

    GenServer.start_link(__MODULE__, db_folder, name: via_tuple(worker_id))
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  def init(db_folder) do
    # TODO: remove!
    # Process.flag(:trap_exit, true)
    # Process.send_after(self(), :tick, 5000)

    {:ok, db_folder}
  end

  def handle_cast({:store, key, data}, db_folder) do
    db_folder
    |> file_name(key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, db_folder}
  end

  def handle_call({:get, key}, _, db_folder) do
    data =
      db_folder
      |> file_name(key)
      |> File.read()
      |> case do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, db_folder}
  end

  # # TODO: remove!
  # def handle_info(:tick, state) do
  #   Process.exit(self(), :kill)

  #   {:noreply, state}
  # end

  def terminate(reason, state) do
    IO.inspect("Terminating: #{inspect(reason)} - #{inspect(state)}")
  end

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end

  defp file_name(db_folder, key) do
    Path.join(db_folder, to_string(key))
  end
end

# spawn(fn ->
#   Process.flag(:trap_exit, true)
#   spawn_link(fn -> raise("Something went wrong") end)

#   receive do
#     msg -> IO.inspect(msg)
#   end
# end)

# Todo.System.start_link()
# [{worker_pid, _}] = Registry.lookup(Todo.ProcessRegistry, {Todo.DatabaseWorker, 2})
