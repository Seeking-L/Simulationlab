using Pkg

Pkg.activate(".")
Pkg.instantiate()

using Revise

include("lib/MyApp.jl")

route("/") do
    MyApp.MyPage |> init |> ui |> html  
end

up(8888)