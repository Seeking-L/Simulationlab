include("support.jl")
include("init.jl")
#创建网页
function ui(model::MyApp.MyPage)
    #交互循环
    onany(model.value) do (_...)
        model.click[] += 1
        if(sort(readdir(FILE_PATH))!=String[])
            model.u0 = vec(float(open(readdlm, joinpath(FILE_PATH, "t1.txt"))))
        end
        change(model)
        compute_data(model)
    end
    # # 删除数据按钮监测
    # on(model.value_rm) do (_...)
    #     remove_data(model)
    # end
    #网页内容
    page(model, class="container", title="二维平板换热虚拟仿真实验室(Two Dimensional Plate Heat Transfer Virtual
        Simulation Laboratory)",
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
                cell(class="st-module", size=8,[
                h2("虚拟仿真平台：二维平板换热实验室")])
                cell(
                    class="st-module", size=3,
                    [
                        # btn("删除数据", color="red", textcolor="black", @click("value_rm += 1"), size="24px",
                        #     [
                        #         tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                        #             style="offset: 10px 10px", "点击删除数据")
                        #     ]
                        # )
                        uploader(label="数据上传", :auto__upload, :multiple, method="POST",
                            url=SERVEURL, field__name="txt_file")
                    ]
                )
            ])
            row([
                cell(
                    size=8,
                    class="st-module",
                    [
                        row([
                        cell(
                            class="st-module",
                            [
                                h5("Result Plot")
                                plot(:plot_data, layout=:layout, config="{ displayLogo:false }")]
                        )])
                    ]
                )
                cell([
                    row([cell(
                        class="st-module",size=10,
                        [
                            h2("&nbsp&nbsp&nbsp"),
                            h6("西边条件"),
                            Stipple.select(:selection1, options=:selections,filled=true,rounded=true),
                            input("", placeholder="对流换热系数h", @bind(:h1), @showif(:showinput1)),
                            input("", placeholder="关于t(时间)的表达式", @bind(:funcstr1))
                        ]
                    )])
                    row([
                    cell(
                        class="st-module",size=10,
                        [
                            h2("&nbsp&nbsp&nbsp"),
                            h6("北边条件"),
                            Stipple.select(:selection2, options=:selections,filled=true,rounded=true),
                            input("", placeholder="对流换热系数h", @bind(:h2), @showif(:showinput2)),
                            input("", placeholder="关于t(时间)的表达式", @bind(:funcstr2))
                        ]
                    )])
                    row([
                    cell(
                        class="st-module",size=10,
                        [
                            h2("&nbsp&nbsp&nbsp"),
                            h6("东边条件"),
                            Stipple.select(:selection3, options=:selections,filled=true,rounded=true),
                            input("", placeholder="对流换热系数h", @bind(:h3), @showif(:showinput3)),
                            input("", placeholder="关于t(时间)的表达式", @bind(:funcstr3))
                        ]
                    )])
                    row([
                    cell(
                        class="st-module",size=10,
                        [
                            h2("&nbsp&nbsp&nbsp"),
                            h6("南边条件:"),
                            Stipple.select(:selection4, options=:selections,filled=true,rounded=true),
                            input("", placeholder="对流换热系数h", @bind(:h4), @showif(:showinput4)),
                            input("", placeholder="关于t(时间)的表达式", @bind(:funcstr4))
                        ]
                    )])
                    row([
                    cell(
                        class="st-module",size=10,
                        [
                            h2("&nbsp&nbsp&nbsp"),
                            h6("内热源: &nbsp&nbsp"),
                            input("", placeholder="关于t(时间)的表达式", @bind(:innerheat))
                        ]
                    )])
                    row([
                    cell(
                        size=8,
                        [
                            btn("Simulation!", color="primary", textcolor="black", @click("value += 1"),
                                [
                                    tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                                        style="offset: 1000px 1000px", "Click the button to start simulation")
                                    h6(["&nbsp&nbspTimes: ",
                                        span(model.click, @text(:click))])
                                ]
                            )
                        ]
                    )])
                ])
            ])
            row([
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

# cell(
# class="st-module",
# [
# h5("Result Data")
# table(:tableData; pagination=:credit_data_pagination, label=false, flat=true)
# ]
# )