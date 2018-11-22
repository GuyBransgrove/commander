defmodule Commander do
  @moduledoc """
  Documentation for Commander.
  """

  @doc """
  main - Main function of Commander. Takes an array of arguments and options and builds a configuration model based on them

  ## Examples

      iex> Commander.handle_main(["test","-test","-othertest","--newtest=test","-nt=newtest","--doubledash"])
      %Config{
        arguments: ["test"],
        options: %{
          "doubledash" => true,
          "newtest" => "test",
          "nt" => "newtest",
          "othertest" => true,
          "test" => true
        }
      }

  """
  def handle_main(args) do
    {_arguments, config} =
      {args, %Config{}}
      |> map_arguments
      |> map_options

    config
  end

  @doc """
  map_arguments - maps all arguments to the appropriate place in the confuration model

  ## Examples

      iex> Commander.map_arguments({["test","-test","-othertest","--newtest=test","-nt=newtest","--doubledash"], %Config{}})
      {["test","-test","-othertest","--newtest=test","-nt=newtest","--doubledash"], %Config{arguments: ["test"], options: %{}}}

  """
  def map_arguments({args, config}) when is_list(args) do
    args_list =
      args
      |> Enum.filter(fn x -> !String.starts_with?(x, "-") end)

    config = %Config{config | arguments: args_list}
    {args, config}
  end

  @doc """
  map_options - maps all options to the appropriate place in the confuration model

  ## Examples

      iex> Commander.map_options({["test","-test","-othertest","--newtest=test","-nt=newtest","--doubledash"], %Config{}})
      {["test","-test","-othertest","--newtest=test","-nt=newtest","--doubledash"], %Config{arguments: [], options: %{"doubledash" => true,"newtest" => "test","nt" => "newtest","othertest" => true,"test" => true}}}

  """
  def map_options({args, config}) when is_list(args) do
    options =
      args
      |> Enum.filter(fn x -> String.starts_with?(x, "-") end)
      |> Enum.map(&Commander.parse_option/1)
      |> Enum.map(&reconcile_equals/1)
      |> Map.new()

    config = %Config{config | options: options}

    {args, config}
  end

  @doc """
  parse_option - takes an option and returns the formatted option

  ## Examples

      iex> Commander.parse_option("--newtest=test")
      "newtest=test"

  """
  def parse_option(arg) do
    trimmedOption =
      case String.starts_with?(arg, "--") do
        true -> String.trim_leading(arg, "--")
        false -> lookup_full_option(arg, %{})
      end

    trimmedOption
  end

  @doc """
  lookup_full_option - takes an abreviated option and returns the full option

  ## Examples

      iex> Commander.lookup_full_option("-t=test", %{"t" => "trythisone"})
      "trythisone=test"

      iex> Commander.lookup_full_option("-x", %{"x" => "anotherone"})
      "anotherone"

  """
  def lookup_full_option(arg, full_options) do
    trimmed = String.trim_leading(arg, "-")
    {key, value} = reconcile_equals(trimmed)
    option = Map.get(full_options, key, key)

    case value !== "" && String.contains?(arg, "=") do
      true -> "#{option}=#{value}"
      false -> option
    end
  end

  defp reconcile_equals(base) do
    case String.contains?(base, "=") do
      true -> handle_valid_equals(base)
      false -> {base, true}
    end
  end

  defp handle_valid_equals(base) do
    [key | values] = String.split(base, "=")
    value = Enum.join(values, "=")
    {key, value}
  end
end
