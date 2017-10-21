defmodule TempActor do
    def listen do
        receive do
            {:ping, value} -> send_pong(value)
            # code
        end
        listen()
    end
    defp send_pong(value) do
        IO.puts "Received ping at #{inspect(self())}"
        IO.puts "Sending pong to master"
        send :master, {:pong, "pong"}
    end
end