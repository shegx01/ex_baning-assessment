defmodule ExBanking.Customer.StagesDynamicSupervisor do
  use DynamicSupervisor
  alias ExBanking.Customer
  alias ExBanking.Customer.{Producer, Consumer}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec start_worker(worker_id :: String.t()) :: :ok | {:error, any}
  def start_worker(worker_id, initial_demand \\ 0) do
    case worker_exists?(worker_id) do
      true ->
        {:error, :user_already_exists}

      false ->
        case start_child_producer({worker_id, initial_demand}) do
          {:ok, _} ->
            start_child_consumer(worker_id)

          {:error, error} ->
            {:error, error}
        end
    end
    |> ensure_worker_started()
  end

  @spec worker_exists?(worker_id :: String.t()) :: boolean()
  def worker_exists?(worker_id) do
    case Registry.lookup(Producer, worker_id) do
      [{_pid, _}] -> true
      [] -> false
    end
  end

  @spec get_pid(registry_id :: atom(), worker_id :: String.t()) :: pid() | nil
  def get_pid(registry_id, worker_id), do: do_get_pid(registry_id, worker_id)

  defp do_get_pid(:producer, worker_id) do
    case Registry.lookup(Producer, worker_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  defp do_get_pid(:consumer, worker_id) do
    case Registry.lookup(Consumer, worker_id) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  # def get_pid(_, _), do: raise(ArgumentError, "invalid registry")

  defp ensure_worker_started({:ok, _}), do: :ok
  defp ensure_worker_started({:error, _} = error), do: error

  def start_child_producer(name) do
    DynamicSupervisor.start_child(__MODULE__, {Customer.Producer, name})
  end

  def start_child_consumer(name) do
    DynamicSupervisor.start_child(__MODULE__, {Customer.Consumer, name})
  end

  def init(_init_arg) do
    DynamicSupervisor.init(
      strategy: :one_for_one
      # extra_arguments: [init_arg]
    )
  end
end
