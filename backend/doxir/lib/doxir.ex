defmodule Doxir do
  @moduledoc """
  Documentation for Doxir.
  """

  import HTTPoison
  import Poison

  @doc """
  Hello world.

  ## Examples

      iex> Doxir.hello()
      :world

  """
  def list_containers do
    %HTTPoison.Response{body: body} = HTTPoison.get! 'http://192.168.173.191:2375/containers/json'
    Poison.decode body
  end
end
