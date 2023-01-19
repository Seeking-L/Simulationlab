using Stipple,StipplePlotly, StippleUI, Genie
include("mysolver.jl")

module MyApp
using Stipple,StipplePlotly, StippleUI, Genie
@reactive mutable struct MyPage <: ReactiveModel
    #define parameter
    chi_P::R{Vector{Float64}} = []
    chi_Tci::R{Vector{Float64}} = []
    chi_Teo::R{Vector{Float64}} = []
    #D_fan::R{Vector{Float64}} = []
    value::R{Int} = 0
    click::R{Int} = 0
    chi_Tei::R{Float64} = 0
    #warin::R{Bool} = true
end
end

function ui(model::MyApp.MyPage)
         #交互循环
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
            heading("HVAC")
            cell(
                class="st-module",
                [
                    h6("ch1_Tei"),
                    input("", placeholder="请输入ch1_Tei", @bind(:chi_Tei)),
                    #textfield("Please input your D_fan *", :D_fan, name = "D_fan")
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
            row([
                cell([
                    Html.div("chi_P : ", class="text-h2", [
                    span("", @text(:chi_P))])
                    ])
                cell([
                    Html.div("chi_Tci : ", class="text-h2", [
                    span("", @text(:chi_Tci))])
                    ])
                cell([
                    Html.div("chi_Teo : ", class="text-h2", [
                    span("", @text(:chi_Teo))])
                    ])
                ])

         ]
    )
end