defmodule GenReport do
  alias GenReport.Parser

  def build(), do: {:error, "Insira o nome de um arquivo"}

  def build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(initial_values(), fn data, reports -> merge_valeus(data, reports) end)
  end

  defp merge_valeus([name, hours, _day, month, year], %{
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

  def initial_values() do
    %{}
    |> Map.put("all_hours", %{})
    |> Map.put("hours_per_month", %{})
    |> Map.put("hours_per_year", %{})
  end
end
