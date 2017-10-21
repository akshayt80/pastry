defmodule Project3 do
  @moduledoc """
  Documentation for Project3.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Project3.hello
      :world

  """
  def main(args) do
      {_, [nodes, requests], _} = OptionParser.parse(args)
      IO.puts "command line arguments: #{inspect(nodes)}"
      nodes = elem(Integer.parse(nodes), 0)
      IO.puts "command line arguments: #{inspect(requests)}"
      requests = elem(Integer.parse(requests), 0)
      TempMaster.init()
      #bit = NodeLogic.different_bit("FE9FCB37C30201F73F142449D037028D", "FE9FC289C3FF0AF142B6D3BEAD98A923")
      #IO.puts "bits differ in two strings at: #{bit}"
  end
end
