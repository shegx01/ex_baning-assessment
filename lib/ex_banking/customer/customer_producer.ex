defmodule ExBanking.Customer.Producer do
  use GenStage
  alias ExBanking.CustomerRegistry
  alias ExBanking.Customer.Transaction
  require Logger

  def start_link(user) do
    GenStage.start_link(__MODULE__, 0, name: via_tuple(user))
  end

  @impl GenStage
  def init(pending_demand) do
    {:producer, {:queue.new(), pending_demand}}
  end

  def via_tuple(worker_id) do
    CustomerRegistry.via_tuple(worker_id)
  end

  # genstage server
  # communicating with `ExBanking` module for transaction struct creation
  # and calling calling queueing process
  @spec create_transaction(any) :: {:error, any} | ExBanking.Customer.Transaction.t()
  def create_transaction(%Transaction{type: :send, from: user} = transaction) do
    Logger.info("transaction of type :send")
    GenStage.call(via_tuple(user), {:verify_transaction, transaction})
  end

  def create_transaction(%Transaction{user: user} = transaction) do
    Logger.info("generic transactions")
    GenStage.call(via_tuple(user), {:transaction, transaction})
  end

  def create_transaction({:error, _} = error), do: error
  def create_transaction(_), do: {:error, :wrong_argument}

  @doc """
    CONSTRAINT 1
    `In every single moment of time the system should handle 10 or less operations for every individual user`

   - I manually managing queueing process and pending transaction demand
     we dont want to push to the system if max 10 active event is in the system.
   - since we manage the queue, the pending demand must be 0 and max demand must be 10
     to guarantee this rule
     so the demand from the consumer must have been satisfied if current pending demand is
     equal to 0 in this producer module

     CONSTRAINT 2
     ` If there is any new operation for this user and he/she still has 10 operations in pending state - new operation for this user should immediately return too_many_requests_to_user`

   - This rule holds automatically since our max demain is 10 from the consumer
  """

  @impl GenStage
  def handle_call({:transaction, transaction}, sender, {queue, pending_demand})
      when pending_demand > 0 do
    queue = :queue.in({sender, transaction}, queue)

    # we would not want to handle transaction here
    # so lets delegate the work it to handle_info/2
    Process.send(self(), :new_transaction, [])
    {:noreply, [], {queue, pending_demand - 1}}
  end

  def handle_call({:transaction, _transaction}, _sender, {queue, pending_demand}) do
    message = {:error, :too_many_requests_to_user}

    {:reply, message, [], {queue, pending_demand}}
  end


    #  validating the constraint of :too_many_requests_to_sender and :too_many_requests_to_sender

  def handle_call(
        {:verify_transaction, %Transaction{from: from, to: to} = transaction},
        sender,
        state
      ) do
    verify_send_transaction(transaction, from, to, sender, state)
  end

  @impl GenStage
  def handle_info(:new_transaction, {queue, pending_demand}) do
    case :queue.out(queue) do
      {{:value, transaction}, queue} ->
        {:noreply, [transaction], {queue, pending_demand}}

      {:empty, queue} ->
        # :queue needs reverse to enable FIFO behavious
        # no performance penalty on such a data
        {:noreply, [], {Enum.reverse(queue), pending_demand}}
    end
  end

  # handing demand
  # minimum number of demand expected is 1
  # thanks to genstage, amy pending demand will be
  # served when the event is available
  @impl GenStage
  def handle_demand(demand, {queue, pending_demand}) do
    case :queue.out(queue) do
      {{:value, transaction}, queue} ->
        {:noreply, [transaction], {queue, demand + pending_demand - 1}}

      {:empty, queue} ->
        {:noreply, [], {Enum.reverse(queue), demand + pending_demand}}
    end
  end


  defp verify_send_transaction(transaction, from, to, sender, {_, pending_demand} = state) do
    case sender == self() do
      true ->
        if pending_demand > 0 do
          GenStage.call(via_tuple(to), {:verify_transaction, transaction})
        else
          message = {:error, :too_many_requests_to_sender}
          {:reply, message, [], state}
        end

      false ->
        if pending_demand > 0 do
          GenStage.call(via_tuple(from), {:transaction, transaction})
        else
          message = {:error, :too_many_requests_to_receiver}
          {:reply, message, [], state}
        end
    end
  end
end
