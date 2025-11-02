defmodule Hpota.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  #use Application
  use Honey, license: "Dual BSD/GPL"

  @sec "tracepoint/syscalls/sys_enter_kill"
  def main(_ctx) do

    nil_var = nil

    Honey.Bpf_helpers.bpf_printk(["Hello, world!", nil_var])
  end

  ### @impl true
  ### def start(_type, _args) do
  ###   children = [
  ###      #Starts a worker by calling:
  ###      Hpota.Worker.start_link(arg)
  ###      {Hpota.Worker, arg}
  ###   ]

  ###   # See https://hexdocs.pm/elixir/Supervisor.html
  ###   # for other strategies and supported options
  ###   opts = [strategy: :one_for_one, name: Hpota.Supervisor]
  ###   Supervisor.start_link(children, opts)
  ### end
end
