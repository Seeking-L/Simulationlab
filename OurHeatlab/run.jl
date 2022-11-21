using Pkg

const SERVEURL = "http://localhost:8888/"  # 本地运行地址

Pkg.activate(".")
Pkg.instantiate()

using Revise

include("lib/ui.jl")

route("/") do
    MyApp.MyPage |> init |> ui |> html
end

up(8888)




