defmodule MultiDict do
  def new(), do: %{}

  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key) do
    Map.get(dict, key, [])
  end
end

defmodule V1.TodoList do
  def new(), do: MultiDict.new()

  def add_entry(todo_list, entry) do
    MultiDict.add(todo_list, entry.date, entry)
  end

  def entries(todo_list, date) do
    MultiDict.get(todo_list, date)
  end
end

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

defimpl Collectable, for: TodoList do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    TodoList.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(todo_list, :halt), do: :ok
end

defmodule Alex do
  def async() do
    run_query = fn query ->
      Process.sleep(2000)
      "#{query} result!"
    end

    run_query.("query 1")
  end

  def run() do
    # File.stream!("./todos.csv")
    # |> Stream.map(fn line -> String.replace(line, "\n", "") end)
    # |> Stream.map(fn line -> String.split(line, ",") end)
    # |> Stream.map(fn [date, title] ->
    #   [year, month, day] =
    #     date
    #     |> String.split("/")
    #     |> Enum.map(&String.to_integer/1)

    #   {{year, month, day}, title}
    # end)
    # |> Enum.map(fn {{year, month, day}, title} ->
    #   %{date: Date.new!(year, month, day), title: title}
    # end)
    # |> TodoList.new()

    entries = [
      %{date: ~D[2018-11-19], title: "Foo"},
      %{date: ~D[2018-11-19], title: "Bar"},
      %{date: ~D[2018-11-21], title: "Baz"}
    ]

    entries

    # todo_list =
    #   TodoList.new(entries)
    #   |> TodoList.add_entry(%{date: ~D[2018-12-19], title: "Dentist"})
    #   |> TodoList.add_entry(%{date: ~D[2018-12-20], title: "Shopping"})
    #   |> TodoList.add_entry(%{date: ~D[2018-12-19], title: "Movies"})

    # TodoList.entries(todo_list, ~D[2018-12-19])

    # todo_list
  end
end

# For reference
defmodule TodoList.CsvImporter do
  def import(file_name) do
    file_name
    |> read_lines()
    |> create_entries()
    |> TodoList.new()
  end

  defp read_lines(file_name) do
    file_name
    |> File.stream!()
    |> Stream.map(&String.replace(&1, "\n", ""))
  end

  defp create_entries(lines) do
    lines
    |> Stream.map(&extract_fields/1)
    |> Stream.map(&create_entry/1)
  end

  defp extract_fields(line) do
    line
    |> String.split(",")
    |> convert_date()
  end

  defp convert_date([date_string, title]) do
    {parse_date(date_string), title}
  end

  defp parse_date(date_string) do
    [year, month, day] =
      date_string
      |> String.split("/")
      |> Enum.map(&String.to_integer/1)

    {:ok, date} = Date.new(year, month, day)

    date
  end

  defp create_entry({date, title}) do
    %{date: date, title: title}
  end
end
