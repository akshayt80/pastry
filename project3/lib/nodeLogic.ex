defmodule NodeLogic do
    require Logger

    def nodeid_generator(id) do
        # 128 bit
        :crypto.hash(:md5, id) |> Base.encode16
    end
    def keyid_generator(key) do
        # 160 bit
        :crypto.hash(:sha, key) |> Base.encode16
    end
    # each nodeId is 32 charcter long as it is 128 bit encrypted
    # if returned value is -1 then no prefix bits matched
    # def different_bit(nodeId1, nodeId2, bit, curr_pos) when (curr_pos == 32) do
    #     bit
    # end
    # def different_bit(nodeId1, nodeId2, bit \\ 0, curr_pos \\ 0) do
    #     char1 = String.at(nodeId1, curr_pos) 
    #     char2 = String.at(nodeId2, curr_pos)
    #     if (char1 == char2) and (bit == curr_pos - 1) do
    #         bit = curr_pos
    #     end
    #     curr_pos = curr_pos + 1
    #     different_bit(nodeId1, nodeId2, bit, curr_pos)
    # end
    def different_bit(nodeId1, nodeId2, base, bit, curr_pos) when (curr_pos == base) do
        # when first bit also doesn't match
        if bit <= 0 do
            bit = 0
        end
        bit
    end
    def different_bit(nodeId1, nodeId2, base, bit \\ -1, curr_pos \\ 0) do
        char1 = String.at(nodeId1, curr_pos) 
        char2 = String.at(nodeId2, curr_pos)
        Logger.debug "char1: #{char1} char2: #{char2}"
        if (char1 == char2) and (bit == curr_pos-1) do
            bit = curr_pos
        end
        curr_pos = curr_pos + 1
        different_bit(nodeId1, nodeId2, base, bit, curr_pos)
    end
    def toBase4String(raw, base) do
        str = Integer.to_string(raw, 4)
        diff = base - String.length(str)
        # add padding of 0 in front
        if diff > 0 do
            str = String.pad_leading(str, base, "0")
        end
        #Logger.debug "raw: #{raw} base4: #{str}"
        str
    end
end