defmodule ExBanking.Customer.StagesDynamicSupervisorTest do
  use ExUnit.Case, async: false
  alias ExBanking.Customer.{StagesDynamicSupervisor, Producer}

  setup do
    %{not_to_run: -10}
  end

  describe "producers handling 10 or less operations at a given time" do
    test "start_work/1", %{not_to_run: not_to_run} do
      user = "Desmond E"
      user2 = "Desmond A"
     StagesDynamicSupervisor.start_worker(user, not_to_run)
     StagesDynamicSupervisor.start_worker(user2)
     user1_pid = Producer.get_pid(user)
     user2_pid = Producer.get_pid(user2)
     user1_demand = :sys.get_state(user1_pid)
     user2_demand = :sys.get_state(user2_pid)
     assert user1_demand.state |> Kernel.elem(1) == 0
     assert user2_demand.state |> Kernel.elem(1) > 0
     assert {:ok, 200.0 } = ExBanking.deposit(user2, 200, "USD")
      assert {:error, :too_many_requests_to_user} = ExBanking.deposit(user, 20, "USD")
      assert {:error, :too_many_requests_to_user} = ExBanking.withdraw(user, 20, "USD")
      assert {:error, :too_many_requests_to_user} = ExBanking.balance(user, "USD")
      assert {:error, :too_many_requests_to_sender} = ExBanking.send(user, user2, 50, "USD")
      assert {:error, :too_many_requests_to_receiver} = ExBanking.send(user2, user, 50, "USD")
      assert {:ok, 200.0 } = ExBanking.balance(user2, "USD")
    end
  end
end
