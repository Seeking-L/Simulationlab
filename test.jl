using Stipple, StippleUI
using StipplePlotly
using CoolProp
using Printf
 
sw = [[PropsSI("S","T",t,"Q",0,"water") for t = 273.06:647.09];[PropsSI("S","T",t,"Q",1,"water") for t = 647.09:-1:273.06]]
dwx = PlotData(x=sw/1000,y=[273.06:647.09;647.09:-1:273.06],name="水的饱和线")

mutable struct xunhuan
	picture::PlotData
	work::Float64
	efficiency::Float64
end

@reactive mutable struct testpage <: ReactiveModel
	circle::R{xunhuan} = xunhuan(PlotData(),0.0,0.0)
	plot_data::R{Vector{PlotData}} = [dwx] 
	layout::R{PlotLayout} = pl()
  	T1::R{Float64} = 298.0
	Tz::R{Float64} = 500.0
  	pw::R{Float64} = 3.0
	continuity::R{Bool} = false
	reheat::R{Bool} = false
	str_work::R{String} = "0.0"
	str_efficiency::R{String} = "0.0s"
end

pl() = PlotLayout(
		plot_bgcolor="#fff",
		title = PlotLayoutTitle(text="朗肯循环温熵图"),
		legend = PlotLayoutLegend(bgcolor = "rgb(212,212,212)", font=Font(6)),
		hovermode = "closest",
		showlegend = true,
		xaxis = [PlotLayoutAxis(xy = "x", index = 1,
					title = "比熵s(kJ/(K*mol))",
					font = Font(18),
					ticks = "outside bottom",
					#side = "bottom",
					#position = 1.0,
					showline = true,
					showgrid = true,
					zeroline = false,
					mirror = true,
					#ticklabelposition = "outside"
				)],
		yaxis = [PlotLayoutAxis(xy = "y", index = 1,
					showline = true,
					zeroline = true,
					mirror = "all",
					showgrid = true,
					title = "热力学温度T/K",
					font = Font(18),
					ticks = "outside",
					scaleratio = 1,
					constrain = "domain",
					constraintoward = "top",
				)],
)

function solveeqution(eqtions, step::Float64, precision::Float64, cauchy::Float64)
	memory = 0
	while true
		memory = eqtions(cauchy)
		if abs(memory)< precision
			return cauchy
		end
		cauchy = cauchy + step
		step = 0.1*step/abs(eqtions(cauchy) - memory)
	end
end

function integral(x, y::Vector{Float64})
	n = length(x)
	s = 0
	for i = 1:n-1
		s = s + (y[i]+y[i+1])*(x[i+1]-x[i])/2
	end
	return s
end

function computeRK(T1::Float64, Tz::Float64, pw::Float64, reheat::Bool)
	c = xunhuan(PlotData(),0.0,0.0)
	x = [3,1]
	s = [PropsSI("S","T",T1,"Q",1,"water"), PropsSI("S","T",T1,"Q",0,"water"), PropsSI("S","T",T1,"Q",0,"water")]
	T = [T1,T1]
	str = "基础理想朗肯循环"
	p0 = PropsSI("P","T",T1,"Q",1,"water")/10^6
	S1(t) = PropsSI("S","T",t,"P|liquid",(p0+pw)*10^6,"water") - s[2]
	t0 = solveeqution(S1, 0.001, 0.1, T1)
	T = [T; t0:PropsSI("T","P",(p0+pw)*10^6,"Q",0,"water")]
	s = [s; PropsSI.("S","T",T[4:end],"P|liquid",(p0+pw)*10^6,"water")]
	T = [T; PropsSI("T","P",(p0+pw)*10^6,"Q",1,"water")]
	s = [s; PropsSI("S","P",(p0+pw)*10^6,"Q",1,"water")]
	S2(x) = PropsSI("S","T|gas",x,"P",(p0+pw)*10^6,"water") - s[1]
	t0 = T[end]
	T2 = solveeqution(S2, 0.1, 0.1, t0)
	T = [T; t0:T2]
	s = [s;PropsSI.("S","T|gas",t0:T2,"P",(p0+pw)*10^6,"water")]
	s[end] = PropsSI("S","T",T1,"Q",1,"water")
	x[2] = length(T)
	if reheat
		S3(p) = PropsSI("S","T|gas",Tz,"P",p*10^6,"water") - s[1]
		p = solveeqution(S3, 0.01, 0.1, p0)
		T = [T;Tz:T2]
		s = [s;PropsSI.("S","T|gas",Tz:T2,"P",p*10^6,"water")]
		x[2] = length(T)
		T = [T; T1]
		s = [s; PropsSI("S","T|gas",T2,"P",p*10^6,"water")]
		str = "带有回热的理想朗肯循环"
	end
	T = [T; T1]
	s = [s; PropsSI("S","T",T1,"Q",1,"water")]/1000
	c.work = integral(s,T)
	c.efficiency = c.work/integral(s[x[1]:x[2]],T[x[1]:x[2]])*100
	c.picture = PlotData(x=s,y=T,name=str)
	return c
end

function ui(model::testpage)

    onany(model.T1) do (_...)
		model.circle[] = computeRK(model.T1[],model.Tz[],model.pw[],model.reheat[])
		model.str_work[] = @sprintf("%6.3f",model.circle[].work)
		model.str_efficiency[] = @sprintf("%2.2f",model.circle[].efficiency)
		if model.continuity[]
			model.plot_data[] = [model.plot_data[];model.circle[].picture]
		else
			model.plot_data[] = [dwx,model.circle[].picture]
		end
    end
    
	onany(model.pw) do (_...)
		model.circle[] = computeRK(model.T1[],model.Tz[],model.pw[],model.reheat[])
		model.str_work[] = @sprintf("%6.3f",model.circle[].work)
		model.str_efficiency[] = @sprintf("%2.2f",model.circle[].efficiency)
		if model.continuity[]
			model.plot_data[] = [model.plot_data[];model.circle[].picture]
		else
			model.plot_data[] = [dwx,model.circle[].picture]
		end
	end

	onany(model.reheat) do (_...)
		model.circle[] = computeRK(model.T1[],model.Tz[],model.pw[],model.reheat[])
		model.str_work[] = @sprintf("%6.3f",model.circle[].work)
		model.str_efficiency[] = @sprintf("%2.2f",model.circle[].efficiency)
		if model.continuity[]
			model.plot_data[] = [model.plot_data[];model.circle[].picture]
		else
			model.plot_data[] = [dwx,model.circle[].picture]
		end
	end

	onany(model.Tz) do (_...)
		model.circle[] = computeRK(model.T1[],model.Tz[],model.pw[],model.reheat[])
		model.str_work[] = @sprintf("%6.3f",model.circle[].work)
		model.str_efficiency[] = @sprintf("%2.2f",model.circle[].efficiency)
		if model.continuity[]
			model.plot_data[] = [model.plot_data[];model.circle[].picture]
		else
			model.plot_data[] = [dwx,model.circle[].picture]
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
			cell([checkbox(label="显示连续变化",fieldname=:continuity,dense=true)])
			cell([checkbox(label="引入再热",fieldname=:reheat,dense=true)])
			])
		row([
			cell(
				class="st-module",
					[
						h5("仿真结果：")
						plot(:plot_data, layout=:layout, config="{ displayLogo:false }")
					]
				)
    		cell([
				cell(
					class="st-module",
						[
							h6("输出净功:")
							h6("",@text(:str_work))
							h6("kJ/mol")
							h6("循环热效率:")
							h6("",@text(:str_efficiency))
							h6("%")
						]
				)
				cell(
        			class="st-module",
        				[
            				h6("泵功(增压/MPa)")
            				slider(0.5:0.01:3,
                			@data(:pw);
                			label=true)
        				]
    			)
        		cell(
		        	class="st-module",
		        		[
    		        		h6("冷却温度(K)")
    		        		slider(280:350,
        		        	@data(:T1);
        		        	label=true)
		        		]
        		)
        		cell(
		        	class="st-module",
		        		[
    		        		h6("再热温度(K)",@showif(:reheat))
    		        		slider(500:800,
        		        	@data(:Tz),
							@showif(:reheat),
        		        	label=true)
		        		]
        		)
    		])
		])
	])
end

route("/") do
    testpage |> init |> ui |> html
end

up(8888)
