using Stipple, StippleUI
using StipplePlotly
using CoolProp
using Printf

include("massdata.jl")

mutable struct xunhuan
    picture::PlotData
    work::Float64
    efficiency::Float64
end

struct StepError <: Exception end
@reactive mutable struct testpage <: ReactiveModel
    #按钮所必要变量 2023-3-1
    value::R{Int} = 0
    click::R{Int} = 0

    circle::R{xunhuan} = xunhuan(PlotData(), 0.0, 0.0)
    plot_data::R{Vector{PlotData}} = []
    layout::R{PlotLayout} = pl()
    T1::R{Float64} = 298.0
    Tz::R{Float64} = 500.0
    pw::R{Float64} = 3.0
    continuity::R{Bool} = false
    reheat::R{Bool} = false
    picture::R{Bool} = true
    str_picture::String = "示热图"
    str_work::R{String} = "0.0"
    str_efficiency::R{String} = "0.0"
    mass_number::R{Int} = 1
    mass_selections::R{Vector{String}} = [mass.name for mass in mass_list]
    mass_selection::R{String} = mass_list[1].name
end

pl() = PlotLayout(
    plot_bgcolor="#fff",
    title=PlotLayoutTitle(text="朗肯循环温熵图(示热图)"),
    legend=PlotLayoutLegend(bgcolor="rgb(212,212,212)", font=Font(6)),
    hovermode="closest",
    showlegend=true,
    xaxis=[PlotLayoutAxis(xy="x", index=1,
        title="比熵s(kJ/(K*kg))",
        font=Font(18),
        ticks="outside bottom",
        #side = "bottom",
        #position = 1.0,
        showline=true,
        showgrid=true,
        zeroline=false,
        mirror=true,
        #ticklabelposition = "outside"
    )],
    yaxis=[PlotLayoutAxis(xy="y", index=1,
        showline=true,
        zeroline=true,
        mirror="all",
        showgrid=true,
        title="热力学温度T/K",
        font=Font(18),
        ticks="outside",
        scaleratio=1,
        constrain="domain",
        constraintoward="top",
    )],
)

plPV() = PlotLayout(
    plot_bgcolor="#fff",
    title=PlotLayoutTitle(text="朗肯循环p-v图(示功图)"),
    legend=PlotLayoutLegend(bgcolor="rgb(212,212,212)", font=Font(6)),
    hovermode="closest",
    showlegend=true,
    xaxis=[PlotLayoutAxis(xy="x", index=1,
        title="比体积v(m^3/kg)",
        font=Font(18),
        ticks="outside bottom",
        #side = "bottom",
        #position = 1.0,
        showline=true,
        showgrid=true,
        zeroline=false,
        mirror=true,
        #ticklabelposition = "outside"
    )],
    yaxis=[PlotLayoutAxis(xy="y", index=1,
        showline=true,
        zeroline=true,
        mirror="all",
        showgrid=true,
        title="压力v/MPa",
        font=Font(18),
        ticks="outside",
        scaleratio=1,
        constrain="domain",
        constraintoward="top",
    )],
)

function solveeqution(eqtions, step::Float64, precision::Float64, cauchy::Float64)
    memory = 0
    error = 0
    while true
        memory = eqtions(cauchy)
        if abs(memory) < precision
            return cauchy
        end
        cauchy = cauchy + step
        step = 0.1 * step / abs(eqtions(cauchy) - memory)
        error += 1
        if error > 10^6
            throw(StepError)
        end
    end
end

function integral(x, y)
    n = length(x)
    s = 0
    for i = 1:n-1
        s = s + (y[i] + y[i+1]) * (x[i+1] - x[i]) / 2
    end
    return s
end

function saturationline(mass::Mass, picture::Bool)
    if picture
        sw = [[PropsSI("S", "T", t, "Q", 0, mass.hname) for t = mass.temperature_limit[1]:mass.temperature_limit[2]]
            [PropsSI("S", "T", t, "Q", 1, mass.hname) for t = mass.temperature_limit[2]:-1:mass.temperature_limit[1]]]
        return PlotData(x=sw/1000,
                y=[mass.temperature_limit[1]:mass.temperature_limit[2]; mass.temperature_limit[2]:-1:mass.temperature_limit[1]], 
                name=mass.name * "的饱和线")
    else
        v = [[1/PropsSI("D", "P", p, "Q", 0, mass.hname) for p = mass.pressure_limit[1]:1000:mass.pressure_limit[2]]
            [1/PropsSI("D", "P", p, "Q", 1, mass.hname) for p = mass.pressure_limit[2]:-1000:mass.pressure_limit[1]]]
        return PlotData(x=v,
                y=[mass.pressure_limit[1]:1000:mass.pressure_limit[2]; mass.pressure_limit[2]:-1000:mass.pressure_limit[1]]/10^6, 
                name=mass.name * "的饱和线")
    end
end

function computeRK(T1::Float64, Tz::Float64, pw::Float64, reheat::Bool, mass::Mass, picture::Bool)
    c = xunhuan(PlotData(), 0.0, 0.0)
    x = [3, 1]
    x2 = 1
    p0 = PropsSI("P", "T", T1, "Q", 1, mass.hname) / 10^6
    Ti = 0
    try
        if picture
            s = [PropsSI("S", "T", T1, "Q", 1, mass.hname), PropsSI("S", "T", T1, "Q", 0, mass.hname), PropsSI("S", "T", T1, "Q", 0, mass.hname)]
            T = [T1, T1]
            str = "基础理想朗肯循环"
            S1(t) = PropsSI("S", "T", t, "P|liquid", (p0 + pw) * 10^6, mass.hname) - s[2]
            t0 = solveeqution(S1, 0.001, 0.1, T1)
            T = [T; t0:PropsSI("T", "P", (p0 + pw) * 10^6, "Q", 0, mass.hname)]
            s = [s; PropsSI.("S", "T", T[4:end], "P|liquid", (p0 + pw) * 10^6, mass.hname)]
            T = [T; PropsSI("T", "P", (p0 + pw) * 10^6, "Q", 1, mass.hname)]
            s = [s; PropsSI("S", "P", (p0 + pw) * 10^6, "Q", 1, mass.hname)]
            S2(x) = PropsSI("S", "T|gas", x, "P", (p0 + pw) * 10^6, mass.hname) - s[1]
            t0 = T[end]
            T2 = solveeqution(S2, 0.1, 0.1, t0)
            T = [T; t0:T2]
            s = [s; PropsSI.("S", "T|gas", t0:T2, "P", (p0 + pw) * 10^6, mass.hname)]
            s[end] = PropsSI("S", "T", T1, "Q", 1, mass.hname)
            x[2] = length(T)
            if reheat
                S3(p) = PropsSI("S", "T|gas", Tz, "P", p * 10^6, mass.hname) - s[1]
                p = solveeqution(S3, 0.01, 0.1, p0)
                T = [T; Tz:T2]
                s = [s; PropsSI.("S", "T|gas", Tz:T2, "P", p * 10^6, mass.hname)]
                x[2] = length(T)
                T = [T; T1]
                s = [s; PropsSI("S", "T|gas", T2, "P", p * 10^6, mass.hname)]
                str = "带有再热的理想朗肯循环"
            end
            T = [T; T1]
            s = [s; PropsSI("S", "T", T1, "Q", 1, mass.hname)] / 1000
            c.work = integral(s, T)
            c.efficiency = c.work / integral(s[x[1]:x[2]], T[x[1]:x[2]]) * 100
            c.picture = PlotData(x=s, y=T, name=str)
        else
            str = "基础理想朗肯循环"
            v = [1/PropsSI("D", "T", T1, "Q", 1, mass.hname), 1/PropsSI("D", "T", T1, "Q", 0, mass.hname)]
            p = [p0;PropsSI("P", "T", T1, "Q", 0, mass.hname)/10^6:0.1:(p0+pw)]
            s1 = PropsSI("S","T",T1,"Q",0,mass.hname)
            s2 = PropsSI("S","T",T1,"Q",1,mass.hname)
            for i in p[3:end]
                Sp1(t) = PropsSI("S","T",t,"P|liquid",i*10^6,mass.hname) - s1
                Ti = solveeqution(Sp1,0.001,0.1,T1)
                v = [v;1/PropsSI("D","T",Ti,"P|liquid",i*10^6,mass.hname)]
            end
            x2 = length(p)
            T0 = PropsSI("T","P",(p0+pw)*10^6,"Q",1,mass.hname)
            Ti = T0 + 0.1
            Tj = Tz + 0.1
            for i = (p0+pw):-0.2:p0
                Tir = Ti
                p = [p;i]
                Sp2(t) = PropsSI("S","T|gas",t,"P",i*10^6,mass.hname) - s2
                if Ti < T0
                    Ti = solveeqution(Sp2,-0.1,0.1,T0)
                else
                    Ti = solveeqution(Sp2,0.1,0.1,T0)
                end
                if reheat
                    str = "带有再热的理想朗肯循环"
                    if (Tir > Tz) && (Ti < Tz)
                        p = [p;i]
                        v = [v;1/PropsSI("D","T|gas",Ti,"P",i*10^6,mass.hname);1/PropsSI("D","T|gas",Tz,"P",i*10^6,mass.hname)]
                        s3 = PropsSI("S","T|gas",Tz,"P",i*10^6,mass.hname)
                        for j = i:-0.2:p0
                            p = [p;j]
                            Sp3(t) = PropsSI("S","T|gas",t,"P",j*10^6,mass.hname) - s3
                            if Tj < Tz
                                Tj = solveeqution(Sp3,-0.1,0.1,Tz)
                            else
                                Tj = solveeqution(Sp3,0.1,0.1,Tz)
                            end
                            v = [v;1/PropsSI("D","T|gas",Tj,"P",j*10^6,mass.hname)]
                        end
                        break
                    end
                    Tir = Ti
                else
                    v = [v;1/PropsSI("D","T|gas",Ti,"P",i*10^6,mass.hname)]
                end
            end
            p = [p;p0]
            v = [v;1/PropsSI("D","P",p0*10^6,"Q",1,mass.hname)]
            c.work = integral(v, p)*1000
            c.efficiency = c.work / integral(v[x2:end], p[x2:end]) * 100
            c.picture = PlotData(x=v, y=p, name=str)
        end
    catch e
        if isa(e,StepError)
            @info "警告!迭代步数过多,程序停止计算!建议改变参数,重新计算!"
        elseif isa(e,ErrorException)
            @info "错误!温度或压强超出了范围,请调整为合适值再做计算!"
        end
    end
    return c
end

function xiabiao(array::Vector{Mass}, value::String)
    for i in eachindex(array)
        value == array[i].name ? (return i) : continue
    end
end

function ui(model::testpage)

    onany(model.mass_selection) do (_...)
        model.mass_number[] = xiabiao(mass_list, model.mass_selection[])
        model.circle[] = computeRK(model.T1[], model.Tz[], model.pw[], model.reheat[], mass_list[model.mass_number[]], model.picture[])
        model.str_work[] = @sprintf("%6.3f", model.circle[].work)
        model.str_efficiency[] = @sprintf("%2.2f", model.circle[].efficiency)
        model.plot_data[] = [saturationline(mass_list[model.mass_number[]], model.picture[])]
        if model.continuity[]
            model.plot_data[] = [model.plot_data[]; model.circle[].picture]
        else
            model.plot_data[] = [saturationline(mass_list[model.mass_number[]], model.picture[]), model.circle[].picture]
        end
    end

    onany(model.picture) do (_...)
        model.str_picture == "示热图" ? (model.str_picture = "示功图"; model.layout[] = plPV()) : (model.str_picture = "示热图"; model.layout[] = pl())
        model.circle[] = computeRK(model.T1[], model.Tz[], model.pw[], model.reheat[], mass_list[model.mass_number[]], model.picture[])
        model.str_work[] = @sprintf("%6.3f", model.circle[].work)
        model.str_efficiency[] = @sprintf("%2.2f", model.circle[].efficiency)
        model.plot_data[] = [saturationline(mass_list[model.mass_number[]], model.picture[])]
        if model.continuity[]
            model.plot_data[] = [model.plot_data[]; model.circle[].picture]
        else
            model.plot_data[] = [saturationline(mass_list[model.mass_number[]], model.picture[]), model.circle[].picture]
        end
    end

    onany(model.value) do (_...)
        model.click[] += 1
        model.circle[] = computeRK(model.T1[], model.Tz[], model.pw[], model.reheat[], mass_list[model.mass_number[]], model.picture[])
        model.str_work[] = @sprintf("%6.3f", model.circle[].work)
        model.str_efficiency[] = @sprintf("%2.2f", model.circle[].efficiency)
        model.plot_data[] = [saturationline(mass_list[model.mass_number[]], model.picture[])]
        if model.continuity[]
            model.plot_data[] = [model.plot_data[]; model.circle[].picture]
        else
            model.plot_data[] = [saturationline(mass_list[model.mass_number[]], model.picture[]), model.circle[].picture]
        end
    end


    page(model,
        class="container",
        title="热力循环演示",
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
              marign: 10px;
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
                cell([checkbox(label="显示连续变化", fieldname=:continuity, dense=true)])
                cell([checkbox(label="引入再热", fieldname=:reheat, dense=true)])
                cell([checkbox(label=model.str_picture, fieldname=:picture, dense=true)])
            ])
            row([
                cell(
                    class="st-module", size=8,
                    [
                        h5("仿真结果：&nbsp&nbsp")
                        plot(:plot_data, layout=:layout, config="{ displayLogo:false }")
                    ]
                )
                cell([
                    cell(
                        cell(
                            class="st-module",
                            [
                                select(:mass_selection, options=:mass_selections)
                            ]
                        )
                    )
                    row([
                        cell(
                            class="st-module",
                            [
                                h6("&nbsp&nbsp 输出净功:&nbsp&nbsp")
                                h6("", @text(:str_work))
                                h6("&nbspkJ/kg")
                            ])
                    ])
                    row([
                        cell(
                            class="st-module",
                            [
                                h6("&nbsp&nbsp 循环热效率:&nbsp&nbsp")
                                h6("", @text(:str_efficiency))
                                h6("&nbsp%")
                            ])
                    ])
                    row([
                        cell(
                            class="st-module",
                            [
                                h6("&nbsp&nbsp 泵功(增压/MPa)")
                                slider(0.01:0.01:20,
                                    @data(:pw);
                                    lazy=true,
                                    label=true)
                            ]
                        )])
                    row([
                        cell(
                            class="st-module",
                            [
                                h6("&nbsp&nbsp 冷却温度(K)")
                                slider(200:800,
                                    @data(:T1);
                                    label=true)
                            ]
                        )])
                    row([
                        cell(
                            class="st-module",
                            [
                                h6("&nbsp&nbsp 再热温度(K)", @showif(:reheat))
                                slider(200:1000,
                                    @data(:Tz),
                                    @showif(:reheat),
                                    label=true)
                            ]
                        )])
                    row([#2023-3-1
                        btn("绘制图像", color="primary", textcolor="black", @click("value += 1"),
                            [
                                tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                                    style="offset: 1000px 1000px", "按下按钮以开始绘图")
                                h6(["&nbsp&nbsp绘制次数: ",
                                    span(model.click, @text(:click))])
                            ]
                        )
                    ])
                ])
            ])
        ])
end

route("/") do
    testpage |> init |> ui |> html
end

up(8889, open_browser=true)
