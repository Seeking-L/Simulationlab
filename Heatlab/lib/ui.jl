include("support.jl")
include("init.jl")
#创建网页
function ui(model::MyApp.MyPage)
    #交互循环
    onany(model.selection1)do(_...)
        change(model)
    end
    onany(model.selection2)do(_...)
        change(model)
    end
    onany(model.selection3)do(_...)
        change(model)
    end
    onany(model.selection4)do(_...)
        change(model)
    end
    onany(model.value) do (_...)
        model.click[] += 1
        if (sort(readdir(FILE_PATH)) != String[])
            model.u0 = vec(float(open(readdlm, joinpath(FILE_PATH, "t1.txt"))))
        end
        change(model)
        compute_data(model)
    end

    #网页内容
    page(model, class="container", title="二维平板换热虚拟仿真实验室(Two Dimensional Plate Heat Transfer Virtual
        Simulation Laboratory)",
        head_content=Genie.Assets.favicon_support(),
        prepend=style(
            """
            tr:nth-child(even) {
              background: rgba(138,171,202,0.3) !important;
            }

            .bg-brand {
                background: #11406c !important;
            }

            .text-brand {
                color: #11406c !important;
            }

            .modebar {
              display: none!important;
            }
            .heading {
                background-color: white;
                color: black;
                text-align:left;
            }
            .st-module {
              position: relative;
              left: 30px;
              padding: 5px;
              border-radius: 5px;
            }
            
            .st-module1 {
                height: 170px;
                width: 300px;
                marign: 20px;
                padding: 15px;
                background: rgba(255,255,255,0.04);
                border-radius: 5px;
                box-shadow: 0px 4px 10px rgba(17,64,108,0.04);
              }
              .st-module2 {
                marign: 5px;
                padding: 10px;
                background: rgba(255,255,255,1);
                border-radius: 5px;
                box-shadow: 0px 4px 10px rgba(17,64,108,0.04);
              }
              .st-module3 {
                height: 70px;
                width: 260px;
                position: relative;
                left: 430px;
                background: rgba(255,255,255,0);
                border-radius: 5px;
              }
              .st-module4 {
                height: 70px;
                width: 260px;
                position: relative;
                left: 430px;
                padding: 7px;
                background: rgba(255,255,255,1);
                border-radius: 5px;
              }
              .st-module5 {
              position: relative;
              top: 0px;
              height:550px;
              width:1500px;
              background-color:rgba(255,255,255,0);
              border-radius: 5px;
            }
            .st-module6 {
              position: relative;
              left: 40px;
              height:400px;
              width:1100px;
              background-color: rgba(255,255,255,1);
              border-radius: 5px;
              box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.04);
            }
            .stipple-core .st-module > h5,
            .stipple-core .st-module > h6 {
              border-bottom: 0px !important;
            }
            """
        ),
        [row(
                [
                    cell(class="st-module", [
                        row([   
                            h1("二维平板传热实验室(Two-dimensional Flat Plate Heat Transfer Lab)")  
                            ])
                        ])
                        uploader(label="初始温度上传", :auto__upload, :multiple, method="POST",
                        url=SERVEURL, field__name="txt_file", color="brand")])
            row(
                class="st-module5",
                [
                    cell([
                        row(class="st-module6",
                            [
                                cell(
                                    [
                                        row([h4("&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbspResult Plot&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp
                                        &nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp")
                                            btn("Table", push=true, color="brand", size="15px", padding="0px 28px", [
                                                popupproxy([
                                                    cell(
                                                        class="st-module2",
                                                        [
                                                            h5("Result Data")
                                                            table(:tableData; pagination=:credit_data_pagination, label=false, flat=true)
                                                        ])
                                                ])
                                            ])
                                        ])
                                        plot(:plot_data, layout=:layout, config="{ displayLogo:false }")]
                                )
                            ])
                    ])
                    cell([
                        row(
                            class="st-module3",
                            [
                                btn("西边条件", push=true, textcolor="brand", color="white", size="25px", padding="5px 80px", [
                                    popupproxy([
                                        cell(
                                            class="st-module1",
                                            [
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        Stipple.select(:selection1, options=:selections, color="indigo-8", label="West")
                                                    ])
                                                    cell(
                                                    class="st-module2",
                                                    [
                                                        input("", placeholder="关于t(时间)的表达式", @bind(:funcstr1))
                                                    ])
                                                    cell(
                                                    class="st-module2",
                                                    [
                                                        h6("对流换热系数h:",@showif(:showinput1))
                                                        input("", placeholder="对流换热系数h", @bind(:h1), @showif(:showinput1))
                                                    ])
                                            ])
                                    ])
                                ])
                            ])
                        row(
                            class="st-module3",
                            [
                                btn("北边条件", push=true, textcolor="brand", color="white", size="25px", padding="5px 80px", [
                                    popupproxy([
                                        cell(
                                            class="st-module1",
                                            [
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        Stipple.select(:selection2, options=:selections, color="indigo-8", label="North")
                                                    ])
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        input("", placeholder="关于t(时间)的表达式", @bind(:funcstr2))
                                                    ])
                                                    cell(
                                                    class="st-module2",
                                                    [
                                                        h6("对流换热系数h:",@showif(:showinput2))
                                                        input("", placeholder="对流换热系数h", @bind(:h2), @showif(:showinput2))
                                                    ])
                                            ])
                                    ])
                                ])
                            ])
                        row(
                            class="st-module3",
                            [
                                btn("东边条件", push=true, textcolor="brand", color="white", size="25px", padding="5px 80px", [
                                    popupproxy([
                                        cell(
                                            class="st-module1",
                                            [
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        Stipple.select(:selection3, options=:selections, color="indigo-8", label="East")
                                                    ])
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        input("", placeholder="关于t(时间)的表达式", @bind(:funcstr3))
                                                    ])
                                                    cell(
                                                    class="st-module2",
                                                    [
                                                        h6("对流换热系数h:",@showif(:showinput3))
                                                        input("", placeholder="对流换热系数h", @bind(:h3), @showif(:showinput3))
                                                    ])
                                            ])
                                    ])
                                ])
                            ])
                        row(
                            class="st-module3",
                            [
                                btn("南边条件", push=true, textcolor="brand", color="white", size="25px", padding="5px 80px", [
                                    popupproxy([
                                        cell(
                                            class="st-module1",
                                            [
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        Stipple.select(:selection4, options=:selections, color="indigo-8", label="South")
                                                    ])
                                                cell(
                                                    class="st-module2",
                                                    [
                                                        input("", placeholder="关于t(时间)的表达式", @bind(:funcstr4))
                                                    ])
                                                    cell(
                                                    class="st-module2",
                                                    [
                                                        h6("对流换热系数h:",@showif(:showinput4))
                                                        input("", placeholder="对流换热系数h", @bind(:h4), @showif(:showinput4))
                                                    ])
                                            ])
                                    ])
                                ])
                            ])
                        row(class="st-module4", [
                            cell(
                                [
                                row(
                                    [
                                    h4("内热源:&nbsp&nbsp "),
                                    input("", placeholder="关于t(时间)的表达式", @bind(:innerheat))
                                ]
                                )
                            ]
                            )])
                        row(class="st-module4", [
                            cell(
                                [
                                row(
                                    [
                                        btn("Simulation!", color="brand", textcolor="white", size="15px", @click("value += 1"),
                                            [
                                                tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                                                    style="offset: 1000px 1000px", "Click the button to start simulation")
                                            ]
                                        )
                                        h6(["&nbsp&nbspTimes: ", span(model.click, @text(:click))])
                                    ]
                                )
                            ]
                            )])
                    ])])
        ]
    )
end
