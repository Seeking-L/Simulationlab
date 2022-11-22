using Stipple, StipplePlotly, StippleUI#, Genie
using DataFrames, CSV, Tables, Dates, Genie.Requests

# 服务设定
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

```
创建文件夹
```
function create_storage_dir(name)
    try
        mkdir(joinpath(@__DIR__, name))
    catch
        @warn "directory already exists"
    end
    return joinpath(@__DIR__, name)
end
# 创建文件夹函数
const FILE_PATH = create_storage_dir("Data_Upload")

# # 删除文件
# function remove_data(model::MyApp.MyPage)
#     files = sort(readdir(FILE_PATH))
#     if files == String[]
#         model.isSuccess[] = string(now()) * "—— 无数据文件!"
#         return []
#     end
#     for i in readdir(FILE_PATH)
#         rm(joinpath(FILE_PATH, i))
#         @info "removing: " * joinpath(FILE_PATH, i)
#     end
#     model.isSuccess[] = string(now()) * "—— 删除$(prod(broadcast(x->" "*x*", ",files)))!"
# end

include("solver.jl")

module MyApp
using Stipple, StipplePlotly, StippleUI, DataFrames
include("solver.jl")
@reactive mutable struct MyPage <: ReactiveModel
    #1.初始化表格
    tableData::R{DataTable} = DataTable(DataFrame(zeros(10, 10), ["$i" for i in 1:10]))
    #1.1.设置表格的显示方式(一页10行)
    credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=10)

    #2.交互所必要变量
    value::R{Int} = 0
    click::R{Int} = 0
    # value_rm::R{Int} = 0

    #3.温度边界条件
    #3.2默认边界
    innerheat::R{String} = "0"
    #3.5求解的时间域(0~timefield)
    timefield::R{Float64} = 100

    selections::R{Vector{String}} = ["第一类边界条件(温度)", "第二类边界条件(热流密度)", "第三类边界条件(对流换热)"]
    selection1::R{String} = "第一类边界条件(温度)"
    selection2::R{String} = "第一类边界条件(温度)"
    selection3::R{String} = "第一类边界条件(温度)"
    selection4::R{String} = "第一类边界条件(温度)"
    showinput1::R{Bool} = false
    showinput2::R{Bool} = false
    showinput3::R{Bool} = false
    showinput4::R{Bool} = false
    funcstr1::R{String} = "0"
    funcstr2::R{String} = "0"
    funcstr3::R{String} = "0"
    funcstr4::R{String} = "0"
    h1::R{Float64} = 0.0
    h2::R{Float64} = 0.0
    h3::R{Float64} = 0.0
    h4::R{Float64} = 0.0
    #4.绘图
    #4.1初始化图片
    plot_data::R{Vector{PlotData}} = []
    #4.2绘制方式
    layout::R{PlotLayout} = PlotLayout(plot_bgcolor="#fff")
end
end






#设置绘图函数
contourPlot(z, n=10, L=0.2) = PlotData(
    x=collect(range(0, L, length=n)),
    y=collect(range(0, L, length=n)),
    z=[z[:, i] for i in 1:10],
    plot=StipplePlotly.Charts.PLOT_TYPE_CONTOUR,
    contours=Dict("start" => 0, "end" => 1000),
    name="test",
)

function change(mo::MyApp.MyPage)
    if mo.selection1[] == "第一类边界条件(温度)"
        boundaryConditions[1].serialNumber = 1
        boundaryConditions[1].bt = mo.funcstr1[]
        mo.showinput1[] = false
    elseif mo.selection1[] == "第二类边界条件(热流密度)"
        boundaryConditions[1].serialNumber = 2
        boundaryConditions[1].qw = mo.funcstr1[]
        mo.showinput1[] = false
    else
        boundaryConditions[1].serialNumber = 3
        boundaryConditions[1].Tf = mo.funcstr1[]
        mo.showinput1[] = true
    end
    if mo.selection2[] == "第一类边界条件(温度)"
        boundaryConditions[3].serialNumber = 1
        boundaryConditions[3].bt = mo.funcstr2[]
        mo.showinput2[] = false
    elseif mo.selection2[] == "第二类边界条件(热流密度)"
        boundaryConditions[3].serialNumber = 2
        boundaryConditions[3].qw = mo.funcstr2[]
        mo.showinput2[] = false
    else
        boundaryConditions[3].serialNumber = 3
        boundaryConditions[3].Tf = mo.funcstr2[]
        mo.showinput2[] = true
    end
    if mo.selection3[] == "第一类边界条件(温度)"
        boundaryConditions[2].serialNumber = 1
        boundaryConditions[2].bt = mo.funcstr3[]
        mo.showinput3[] = false
    elseif mo.selection3[] == "第二类边界条件(热流密度)"
        boundaryConditions[2].serialNumber = 2
        boundaryConditions[2].qw = mo.funcstr3[]
        mo.showinput3[] = false
    else
        boundaryConditions[2].serialNumber = 3
        boundaryConditions[2].Tf = mo.funcstr3[]
        mo.showinput3[] = true
    end
    if mo.selection4[] == "第一类边界条件(温度)"
        boundaryConditions[4].serialNumber = 1
        boundaryConditions[4].bt = mo.funcstr4[]
        mo.showinput4[] = false
    elseif mo.selection4[] == "第二类边界条件(热流密度)"
        boundaryConditions[4].serialNumber = 2
        boundaryConditions[4].qw = mo.funcstr4[]
        mo.showinput4[] = false
    else
        boundaryConditions[4].serialNumber = 3
        boundaryConditions[4].Tf = mo.funcstr4[]
        mo.showinput4[] = true
    end
end

#设置计算函数与绘图的接口
function compute_data(ic_model::MyApp.MyPage)
    timefield = ic_model.timefield[]
    innerheat = ic_model.innerheat[]
    res = get_data(timefield, boundaryConditions, innerheat, p)
    len = length(res[1, 1, :])
    for i in 1:len
        ic_model.plot_data[] = [contourPlot(res[:, :, i])]
        ic_model.tableData[] = DataTable(
            DataFrame(round.(res[:, :, i], digits=2), ["$i" for i in 1:10]))
        sleep(1 / 30)
    end
    nothing
end

#创建网页
function ui(model::MyApp.MyPage)
    #交互循环
    onany(model.value) do (_...)
        model.click[] += 1
        change(model)
        compute_data(model)
    end
    #网页内容
    page(model, class="container", title="二维平板换热虚拟仿真实验室(Two Dimensional Plate Heat Transfer Virtual Simulation Laboratory)",
        head_content=Genie.Assets.favicon_support(),
        prepend=style(
            """
            tr:nth-child(even) {
              background: #F8F8F8 !important;
            }

            .modebar {
              display: none!important;
            }

            .st-module {
              marign: 20px;
              background-color: #FFF;
              border-radius: 5px;
              box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.04);
            }

            .stipple-core .st-module > h5,
            .stipple-core .st-module > h6 {
              border-bottom: 0px !important;
            }
            """
        ),
        [
            row([
                cell(
                    class="st-module", size=3,
                    [
                        uploader(label="数据上传", :auto__upload, :multiple, method="POST",
                            url=SERVEURL, field__name="csv_file")
                    ]
                )
                cell(
                    size=3,
                    class="st-module",
                    [
                        h5("Result Plot")
                        plot(:plot_data, layout=:layout, config="{ displayLogo:false }")
                    ]
                )
                cell([
                    cell(
                        class="st-module",
                        [
                            h6("平板西边条件设置"),
                            Stipple.select(:selection1, options=:selections),
                            input("", placeholder="请输入对流换热系数h", @bind(:h1), @showif(:showinput1)),
                            input("", placeholder="请输入关于t(时间)的表达式", @bind(:funcstr1))
                        ]
                    )
                    cell(
                        class="st-module",
                        [
                            h6("平板北边条件设置"),
                            Stipple.select(:selection2, options=:selections),
                            input("", placeholder="请输入对流换热系数h", @bind(:h2), @showif(:showinput2)),
                            input("", placeholder="请输入关于t(时间)的表达式", @bind(:funcstr2))
                        ]
                    )
                    cell(
                        class="st-module",
                        [
                            h6("平板东边条件设置"),
                            Stipple.select(:selection3, options=:selections),
                            input("", placeholder="请输入对流换热系数h", @bind(:h3), @showif(:showinput3)),
                            input("", placeholder="请输入关于t(时间)的表达式", @bind(:funcstr3))
                        ]
                    )
                    cell(
                        class="st-module",
                        [
                            h6("平板南边条件设置"),
                            Stipple.select(:selection4, options=:selections),
                            input("", placeholder="请输入对流换热系数h", @bind(:h4), @showif(:showinput4)),
                            input("", placeholder="请输入关于t(时间)的表达式", @bind(:funcstr4))
                        ]
                    )
                    cell(
                        class="st-module",
                        [
                            h6("内热源设置"),
                            input("", placeholder="请输入关于t(时间)的表达式", @bind(:innerheat))
                        ]
                    )
                    cell(
                        class="st-module",
                        [
                            btn("Simulation!", color="primary", textcolor="black", @click("value += 1"),
                                [
                                    tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                                        style="offset: 10px 10px", "Click the button to start simulation")
                                    h6(["Simulation Times: ",
                                        span(model.click, @text(:click))])
                                ]
                            )
                        ]
                    )
                ])
            ])
        ]
    )
end


#cell(
#class="st-module",
#[
#h5("Result Data")
#table(:tableData; pagination=:credit_data_pagination, label=false, flat=true)
#]
#)