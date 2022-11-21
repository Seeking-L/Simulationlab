using Stipple, StipplePlotly, StippleUI, Genie
using DataFrames

include("module.jl")
include("solver.jl")

#设置绘图函数
contourPlot(z, n=10, m=10, Lx=0.2, Ly=0.2) = PlotData(
    x=collect(range(0, Lx, length=n)),
    y=collect(range(Ly, 0, length=m)),
    z=[z[i,:] for i in 1:m],
    plot=StipplePlotly.Charts.PLOT_TYPE_CONTOUR,
    contours=Dict("start" => 0, "end" => 1000),
    name="test",
)

function change(mo::MyApp.MyPage)
    #西边
    if mo.selection1[] == "第一类边界条件(温度)"
        boundaryConditions[1].serialNumber = 1
        boundaryConditions[1].bt = mo.funcstr1[]
        mo.showinput1[] = false
    elseif mo.selection1[] == "第二类边界条件(热流密度)"
        boundaryConditions[1].serialNumber = 2
        boundaryConditions[1].qw = mo.funcstr1[]
        mo.showinput1[] = false
    elseif mo.selection1[] == "第三类边界条件(对流换热)"
        boundaryConditions[1].serialNumber = 3
        boundaryConditions[1].Tf = mo.funcstr1[]
        mo.h[1] = mo.h1[]
        mo.showinput1[] = true
    end
    #北边
    if mo.selection2[] == "第一类边界条件(温度)"
        boundaryConditions[2].serialNumber = 1
        boundaryConditions[2].bt = mo.funcstr2[]
        mo.showinput2[] = false
    elseif mo.selection2[] == "第二类边界条件(热流密度)"
        boundaryConditions[2].serialNumber = 2
        boundaryConditions[2].qw = mo.funcstr2[]
        mo.showinput2[] = false
    elseif mo.selection2[] == "第三类边界条件(对流换热)"
        boundaryConditions[2].serialNumber = 3
        boundaryConditions[2].Tf = mo.funcstr2[]
        mo.h[2] = mo.h2[]
        mo.showinput2[] = true
    end
    #东边
    if mo.selection3[] == "第一类边界条件(温度)"
        boundaryConditions[3].serialNumber = 1
        boundaryConditions[3].bt = mo.funcstr3[]
        mo.showinput3[] = false
    elseif mo.selection3[] == "第二类边界条件(热流密度)"
        boundaryConditions[3].serialNumber = 2
        boundaryConditions[3].qw = mo.funcstr3[]
        mo.showinput3[] = false
    elseif mo.selection3[] == "第三类边界条件(对流换热)"
        boundaryConditions[3].serialNumber = 3
        boundaryConditions[3].Tf = mo.funcstr3[]
        mo.h[3] = mo.h3[]
        mo.showinput3[] = true
    end
    #南边
    if mo.selection4[] == "第一类边界条件(温度)"
        boundaryConditions[4].serialNumber = 1
        boundaryConditions[4].bt = mo.funcstr4[]
        mo.showinput4[] = false
    elseif mo.selection4[] == "第二类边界条件(热流密度)"
        boundaryConditions[4].serialNumber = 2
        boundaryConditions[4].qw = mo.funcstr4[]
        mo.showinput4[] = false
    elseif mo.selection4[] == "第三类边界条件(对流换热)"
        boundaryConditions[4].serialNumber = 3
        boundaryConditions[4].Tf = mo.funcstr4[]
        mo.h[4] = mo.h4[]
        mo.showinput4[] = true
    end
end

#设置计算函数与绘图的接口
function compute_data(ic_model::MyApp.MyPage)
    timefield = ic_model.timefield[]
    innerheat = ic_model.innerheat[]
    res = get_data(timefield, boundaryConditions, innerheat, [p;ic_model.h])
    len = length(res[1, 1, :])
    for i in 1:len
        ic_model.plot_data[] = [contourPlot(res[:, :, i])]
        ic_model.tableData[] = DataTable(
            DataFrame(round.(res[:, :, i], digits=2), ["$i" for i in 1:10]))
        sleep(1 / 30)
    end
    nothing
end