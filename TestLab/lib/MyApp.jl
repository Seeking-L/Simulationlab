using Stipple, StipplePlotly, StippleUI

module MyApp
using Stipple, StipplePlotly, StippleUI, DataFrames
@reactive mutable struct MyPage <: ReactiveModel
    value::R{Int} = 0
    click::R{Int} = 0

    features::R{Vector{String}} = ["sin(x)", "cos(x)", "log(x)", "tanh(x)","IWrite"]
    f_left::R{String} = "sin(x)"
    f_right::R{String} = "sin(x)"
    fcn_as_string::R{String} = "x+1"#曲线3的默认输入

    plot_data::R{Vector{PlotData}} = []
    layout::R{PlotLayout} = PlotLayout(plot_bgcolor="#fff")

    x_limit::R{Int} = 3
    paramenter::R{Float32} = 1.2

    #尝试使用select，尚未成功，先不删，说不定stipple作者会告诉怎么做
    chipsname::R{String} = "sin(x)"

    #设置参数，控制输入框是否出现
    showInput::R{Bool} = chipsname=="IWrite"

end
end

function fcnFromString(s)#将字符串转换为函数式子
    f = eval(Meta.parse("x -> " * s))
    return x -> Base.invokelatest(f, x)
end

pd(f, para, xlim, name) = PlotData(
    x=Float64[i for i in 1:0.1:xlim],
    y=Float64[para * f(i) for i in 1:0.1:xlim],
    plot=StipplePlotly.Charts.PLOT_TYPE_SCATTER,
    name=name,
)


function compute_data(ic_model::MyApp.MyPage)
    #从reactive struct中取得字符串，并转化为函数赋给下面三个
    f_left=fcnFromString(ic_model.f_left[])
    f_right=fcnFromString(ic_model.f_right[])
    fx=fcnFromString(ic_model.fcn_as_string[])

    xlim = ic_model.x_limit[]
    para = ic_model.paramenter[]
    for i in 0:30
        ic_model.plot_data[] = [pd(f_left, para, xlim + i, "测试函数1"), pd(f_right, para, xlim + i, "测试函数2"), pd(fx, para, xlim + i, "测试函数3")]
        sleep(1 / 30)
    end
    nothing
end

function ui(model::MyApp.MyPage)

    onany(model.value) do (_...)
        model.click[] += 1
        compute_data(model)
    end

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
            heading("测试")
            row([
                cell(
                    class="st-module",
                    [
                        h6("X轴范围")
                        slider(1:1:20,
                            @data(:x_limit);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("函数系数")
                        slider(1:0.1:2,
                            @data(:paramenter);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("测试函数1")
                        Stipple.select(:f_left; options=:features)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("测试函数2")
                        Stipple.select(:f_right, options=:features)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("测试函数3")
                        input("", placeholder="input fx", @bind(:fcn_as_string),@showif(:showInput))
                    ]
                )
            ])
            row([
                cell(
                    checkbox(label = "IWrite", fieldname = :showInput, dense = true)
                )
            ])
            row([
                cell(
                    class="st-module",
                    p([
                        "Simulation Times: "
                        span(model.click, @text(:click))
                    ])
                )
                btn("Simulation!", color="primary", textcolor="black", @click("value += 1"), [
                    tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                        style="offset: 10px 10px", "点击按钮开始仿真!")])
                cell(
                    class="st-module",
                    p([
                        "Simulation Times: "
                        span(model.click, @text(:click))
                    ])
                )])
            row([
                cell(
                    class="st-module",
                    [
                        h5("仿真结果：")
                        plot(:plot_data, layout=:layout, config="{ displayLogo:false }")
                    ]
                )
            ])
        ]
    )
end
