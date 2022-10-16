using Stipple, StipplePlotly, StippleUI, Genie
using DataFrames

include("solver.jl") # get_data from solver.jl

module MyApp
using Stipple,StipplePlotly, StippleUI, DataFrames
@reactive mutable struct MyPage <: ReactiveModel
    #1.初始化表格
    tableData::R{DataTable} = DataTable(DataFrame(zeros(10,10), ["$i" for i in 1:10]))
    #1.1.设置表格的显示方式(一页10行)
    credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=10)

    #2.交互所必要变量
    value::R{Int} = 0
    click::R{Int} = 0

    #3.温度边界条件
    #3.1可选的函数表单
    func_features::R{Vector{Symbol}} = [:_sin, :_tanh, :_sign]
    #3.2默认边界
    func::R{Symbol} = :_sign
    #3.3初始温度
    T0::R{Float64} = 1500.0
    #3.4环境温度
    Tout::R{Float64} = 0.0
    #3.5求解的时间域(0~timefield)
    timefield::R{Float64} = 100
    #3.6影响温度边界条件的常数
    para::R{Float64} = 1.0

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

#设置计算函数与绘图的接口
function compute_data(ic_model::MyApp.MyPage)
    T0 = ic_model.T0[]
    Tout = ic_model.Tout[]
    timefield = ic_model.timefield[]
    res = get_data(T0, Tout, timefield)
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
        compute_data(model)
    end
    #网页内容
    page(model, class="container", title="Ai4Lab",
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
            heading("二维平板换热虚拟仿真实验室(Two Dimensional Plate Heat Transfer Virtual Simulation Laboratory)")
            row([
                cell(
                    class="st-module",
                    [
                        h6("Initial Temperature: T0(℃)")
                        slider(1000:50:2000,
                            @data(:T0);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Environmental Temperature: Tout(℃)")
                        slider(0:50:500,
                            @data(:Tout);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Coefficient of t: Para")
                        slider(0:0.1:2,
                            @data(:para);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Time Domain(s)")
                        slider(40:20:400,
                            @data(:timefield);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Change of Environmental Temperature")
                        Stipple.select(:func; options=:func_features)
                    ]
                )])
            row([
                btn("Simulation!", color="primary", textcolor="black", @click("value += 1"), [
                    tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                        style="offset: 10px 10px", "Click the button to start simulation")])
                cell(
                    class="st-module",
                    [
                        h6(["Simulation Times: ",
                            span(model.click, @text(:click))])
                    ])
            ])
            row([
                cell(
                    size=6,
                    class="st-module",
                    [
                        h5("Result Plot")
                        plot(:plot_data, layout=:layout, config="{ displayLogo:false }")
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h5("Result Data")
                        table(:tableData; pagination=:credit_data_pagination, label=false, flat=true)
                    ]
                )
            ])
        ]
            
    )
end