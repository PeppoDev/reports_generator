defmodule GenReport do
  alias GenReport.Parser

  def build(), do: {:error, "Insira o nome de um arquivo"}

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(initial_values(), fn data, reports -> merge_values(data, reports) end)
  end

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(initial_values(), fn {:ok, result}, report -> merge_reports(result, report) end)
  end

  defp merge_reports(
         %{
           "all_hours" => all_hours,
           "hours_per_month" => hours_per_month,
           "hours_per_year" => hours_per_year
         },
         %{
           "all_hours" => old_all_hours,
           "hours_per_month" => old_hours_per_month,
           "hours_per_year" => old_hours_per_year
         }
       ) do
    merge_deeply = fn value, value2 -> merge_map(value, value2) end

    merged_all = merge_map(all_hours, old_all_hours)

    merged_per_month = merge_map(hours_per_month, old_hours_per_month, merge_deeply)

    merged_per_year = merge_map(hours_per_year, old_hours_per_year, merge_deeply)

    serialize_values(merged_all, merged_per_month, merged_per_year)
  end

  defp merge_values([name, hours, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    all_hours = Map.put(all_hours, name, sum_value(hours, all_hours[name]))

    hours_per_month_by_name = hours_per_month[name]

    hours_per_month =
      Map.put(hours_per_month, name, sum_by_key(hours_per_month_by_name, month, hours))

    hours_per_year_by_name = hours_per_year[name]

    hours_per_year =
      Map.put(hours_per_year, name, sum_by_key(hours_per_year_by_name, year, hours))

    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }

    serialize_values(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_value(value, old_value) when not is_nil(old_value), do: value + old_value
  defp sum_value(value, old_value) when is_nil(old_value), do: value

  defp sum_by_key(map, key, value) when is_nil(map),
    do:
      %{}
      |> Map.put(key, value)

  defp sum_by_key(map, key, value) when not is_nil(map) do
    map
    |> Map.put(key, sum_value(value, map[key]))
  end

  defp merge_map(new_map, old_map, function) do
    Map.merge(new_map, old_map, fn _k, value, old_value ->
      function.(value, old_value)
    end)
  end

  defp merge_map(new_map, old_map) do
    Map.merge(new_map, old_map, fn _k, value, old_value ->
      sum_value(value, old_value)
    end)
  end

  defp serialize_values(all_hours, hours_per_month, hours_per_year),
    do: %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }

  def initial_values() do
    %{}
    |> Map.put("all_hours", %{})
    |> Map.put("hours_per_month", %{})
    |> Map.put("hours_per_year", %{})
  end
end
