defmodule Hpota do
  use Honey, license: "Dual BSD/GPL"

  defmap(
    :Count_Sys_Calls_Invoked,
    %{
      type: BPF_MAP_TYPE_ARRAY, max_entries: 335, print: true,
      print_elem: [{"SysRead:", 0}, {"SysWrite:", 1}, {"SysKill:", 62}, {"SysMkdir:", 83}, {"SysGetRandom:", 318}]
    }
  )


  @sec "tracepoint/raw_syscalls/sys_enter"
  def main(ctx) do
    id = ctx.id

    id_count = Honey.Bpf_helpers.bpf_map_lookup_elem(:Count_Sys_Calls_Invoked, id)
    Honey.Bpf_helpers.bpf_map_update_elem(:Count_Sys_Calls_Invoked, id, id_count + 1)
    0 # return :ok
  end
  @moduledoc """
  Documentation for `Hpota`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Hpota.hello()
      :world

  """
  def hello do
    :world
  end
end
