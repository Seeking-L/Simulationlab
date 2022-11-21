using Stipple

@reactive mutable struct Name <: ReactiveModel
  name::R{String} = "World!"
  x::R{Float64} = 0.0
  y::R{Float64} = 0.0
end

function ui(model)
  page( model, class="container", [
      h1([
        "Hello "
        span(model.x, @text(:(Float64)(x+y)))
      ])

      p([
        "What is your name? "
        input("", placeholder="Type your name", @bind(:x))
        input("", placeholder="Type your name", @bind(:y))
      ])
    ]
  )
end

route("/") do
  model = Name |> init
  html(ui(model), context = @__MODULE__)
end

up() # or `up(open_browser = true)` to automatically open a browser window/tab when launching the app