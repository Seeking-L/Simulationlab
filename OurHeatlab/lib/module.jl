module MyApp
using Stipple,StipplePlotly, StippleUI, DataFrames
include("solver.jl")
@reactive mutable struct MyPage <: ReactiveModel
    #1.初始化表格
    tableData::R{DataTable} = DataTable(DataFrame(zeros(10,10), ["$i" for i in 1:10]))
    #1.1.设置表格的显示方式(一页10行)
    credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=10)

    #2.交互所必要变量
    value::R{Int} = 0
    click::R{Int} = 0

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

    #1.1.4对流换热系数
    h::Vector{Float64} = [0.0,0.0,0.0,0.0]
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