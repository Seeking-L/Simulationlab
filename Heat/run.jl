using Pkg

# const SERVEURL = "http://localhost:8888/"  # 本地运行地址

##2023-2-20
const SERVEURL = "http://localhost:8888/upload"  # 本地运行地址
const FILE_PATH = "lib/upload/file.txt"

Pkg.activate(".")
Pkg.instantiate()

using Revise

include("lib/ui.jl")


route("/") do
    # MyApp.MyPage |> init |> ui |> html
    model = MyApp.MyPage |> init
    html(ui(model), context = @__MODULE__)
end

#2023-2-20
route("/upload", method = POST) do
    if infilespayload(:txt)
      @info filename(filespayload(:txt))
      @info filespayload(:txt).data
  
      open(FILE_PATH, "w") do io
        write(FILE_PATH, filespayload(:txt).data)
      end
    else
      @info "No file uploaded"
    end
end

up(8888)




