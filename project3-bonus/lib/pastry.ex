defmodule Pastry do
    def pastryInit(cerdentials, application) do
        # credentials to authenticate a node
        # To add to exisiting or create new network
    end
    def route(msg, key) do
        # use this key to route the message to the nearest key
    end
    def deliver(msg, key) do
        # msg has reached the nearest node and now the message will be sent to one of the local nodes
    end
    def forward(msg, key, nextId) do
        # setting nextId as null results in terminating at localnode
    end
    def newLeafs(leafSet) do
        # adjust application-specific invariants based on the leaf set.
    end
end