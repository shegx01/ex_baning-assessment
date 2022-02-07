defmodule ExBanking.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias ExBanking.Customer
  alias ExBanking.Customer

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # map based supervisor
     {Cachex, name: Customer.DataStore},
     ExBanking.CustomerRegistry,
     Customer.Supervisor,
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
