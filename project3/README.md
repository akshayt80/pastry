# Project3

READ ME file for Distributed Operating Systems - Project 3, Due Date: 23rd October,2017

Group members:

Team 3
1. Anmol Khanna, UFID:65140549, anmolkhanna93@ufl.edu,
2. Akshay Singh Jetawat, UFID:22163183, akshayt80@ufl.edu,

# What is working 
We have implemented the Pastry protocol as described in the paper as given in the project specifications. The route and the join mechanisms are also working.

# Largest network managed

We tested for different combinations of number of nodes and number of requests. Below are some of the readings for the same:

|Nodes |Requests	|Avg Hops|
|------|--------- |-------|
|10	   |10        |1.06 	 |
|100	  |10  	     |2.253	 |
|100	  |100 	     |2.2846 |
|500	  |10  	     |3.0872 |
|500   |100       |3.11706|
|1000	 |10  	     |3.5148	|
|1000  |100       |3.53418|
|2000  |10        |3.86925|
|10000 |20000     |4.74   |
 ## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `project3` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:project3, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/project3](https://hexdocs.pm/project3).

