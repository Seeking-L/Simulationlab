function fcnFromString(s)
    f = eval(Meta.parse("x -> " * s))
    return x -> Base.invokelatest(f, x)
end

function main()
    s = "sin.(2*pi*x)"
    f = fcnFromString(s)
    f(1.)
end

