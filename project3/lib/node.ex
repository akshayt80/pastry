defmodule Node do
    def init(numNodes, numRequests, id, base, nodeIdspace) do
        # try using set
        larger_leafs = []#MapSet.new
        smaller_leafs = []#Mapset.new
        table = [] # %{}
        numOfBack = 0

        for i <- 0..base do
            table = table ++ [[-1, -1, -1, -1]]
        end
        # can be removed if we are using hash
        defp toBase4String(raw, base) do
            str = Integer.to_string(raw, 4)
            diff = base - String.length(str)
            # add padding of 0 in front
            if diff > 0 do
                str = String.pad_leading(str, base, "0")
            end
            str
        end
        # TODO:- Check this logic
        defp different_bit(nodeId1, nodeId2, bit, curr_pos) when (curr_pos == base) do
            bit
        end
        defp different_bit(nodeId1, nodeId2, bit \\ 0, curr_pos \\ 0) do
            char1 = String.at(nodeId1, curr_pos) 
            char2 = String.at(nodeId2, curr_pos)
            if (char1 == char2) and (bit == curr_pos) do
                bit = curr_pos
            end
            curr_pos = curr_pos + 1
            different_bit(nodeId1, nodeId2, bit, curr_pos)
        end

        defp add_buffer(all) do
            for i <- all do
                if i > id and not(Enum.member?(larger_leafs, i)) do
                    if length(larger_leafs) < 4 do
                        larger_leafs = larger_leafs ++ [i]
                    else
                        if i < Enum.max(larger_leafs) do
                            larger_leafs = larger_leafs -- [Enum.max(larger_leafs)]
                            larger_leafs = larger_leafs ++ [i]
                        end
                    end
                else
                    if i < id and not(Enum.member?(smaller_leafs, i)) do
                        if length(smaller_leafs) < 4 do
                            smaller_leafs = smaller_leafs ++ [i]
                        else
                            if i > Enum.min(smaller_leafs) do
                                smaller_leafs = smaller_leafs -- [Enum.min(smaller_leafs)]
                                smaller_leafs = smaller_leafs ++ [i]
                            end
                        end
                    end
                end
                # TODO:- this is pending
                samePrefix = different_bit(toBase4String(id, base), toBase4String(i, base))
                if  do
                  
                end
            end
        end
    end
    defp listen() do
        receive do
            {:startRouting, value} ->
            {:initialJoin, value} ->
            {:route, value} ->
            {:addRow, {rowNum, newRow}} ->
            {:addLeaf, allLeaf} ->
            {:update, newNodeId} ->
            {:acknowledgement, value} ->
            {:displayLeafAndRouting, value} ->
        end
        listen()
    end
end