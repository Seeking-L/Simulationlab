using Pkg

Pkg.activate(".")
Pkg.instantiate()

include("lib/ui.jl")

const SERVEURL = "http://localhost:8888/"  # 本地运行地址

route("/") do
    MyApp.MyPage |> init |> ui |> html
end

up(8888,open_browser = true)




