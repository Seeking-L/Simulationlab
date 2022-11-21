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
                    size=6,
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