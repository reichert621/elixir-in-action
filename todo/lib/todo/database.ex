defmodule Todo.Database do
  # use GenServer

  @pool_size 3
  @db_folder "./persist"

  def start_link() do
    File.mkdir_p!(@db_folder)

    children = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  defp worker_spec(worker_id) do
    default_worker_spec = {Todo.DatabaseWorker, {@db_folder, worker_id}}

    Supervisor.child_spec(default_worker_spec, id: worker_id)
  end

  defp choose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end

  # def start() do
  #   IO.inspect("Starting database server.")

  #   GenServer.start(__MODULE__, nil, name: __MODULE__)
  # end

  # def start_link(_) do
  #   IO.inspect("Starting database server.")

  #   GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  # end

  # def init(_) do
  #   File.mkdir_p!(@db_folder)

  #   {:ok, start_workers()}
  # end

  # def handle_call({:choose_worker, key}, _, workers) do
  #   worker_key = :erlang.phash2(key, 3)

  #   {:reply, Map.get(workers, worker_key), workers}
  # end

  # defp start_workers() do
  #   Map.new(0..2, fn n ->
  #     {:ok, pid} = Todo.DatabaseWorker.start_link({@db_folder, n})

  #     {n, pid}
  #   end)
  # end

  # defp choose_worker(key) do
  #   GenServer.call(__MODULE__, {:choose_worker, key})
  # end
end

# {:ok, cache} = Todo.Cache.start()
# bobs_list = Todo.Cache.server_process(cache, "bobs_list")
# Todo.Server.add_entry(bobs_list, %{date: ~D[2018-12-19], title: "Dentist"})
# Todo.Server.entries(bobs_list, ~D[2018-12-19])

# alex_list = Todo.Cache.server_process(cache, "alex_list")
# Todo.Server.add_entry(alex_list, %{date: ~D[2018-12-19], title: "Movies"})
# Todo.Server.entries(alex_list, ~D[2018-12-19])
