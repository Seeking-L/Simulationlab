using DifferentialEquations: ODEProblem, solve, Tsit5

#1.1.1热扩散系数
a = 1.27E-5
#1.1.2密度
density = 1
#1.1.3比热容
c = 1
#1.1.4对流换热系数
h = 1
#1.2表征格点个数(x,y方向离散步长相同)
n = 10
#1.3板长(正方形板)
L = 0.2
#1.4离散步长
δ = L / n
#1.5化简方程所得常数与傅里叶数相差一时间,可以看作时间常数
A = a / δ^2

p = [A,density,c,δ,h]

mutable struct boundaryCondition
    serialNumber::Int
    bt::String
    qw::String
    Tf::String
end

boundaryConditions = [boundaryCondition(1, "0", "0", "500") for i = 1:4]
internalHeatSource(t) = 0

#字符串转换函数
function fcnFromString(s)
    f = eval(Meta.parse("t -> " * s))
    return t -> Base.invokelatest(f, t)
end

Tf1 = fcnFromString(boundaryConditions[1].Tf)
Tf2 = fcnFromString(boundaryConditions[2].Tf)
Tf3 = fcnFromString(boundaryConditions[3].Tf)
Tf4 = fcnFromString(boundaryConditions[4].Tf)

#索引函数
function to_index(i, j, n)
    return (i - 1) * n + j
end

function get_data(time::Float64, boundaryConditions::Vector{boundaryCondition}, innerheat::String, p::Vector{Float64})
    #1.6.1设置内热源
    internalHeatSource = fcnFromString(innerheat)
    Tf1 = fcnFromString(boundaryConditions[1].Tf)
    Tf2 = fcnFromString(boundaryConditions[2].Tf)
    Tf3 = fcnFromString(boundaryConditions[3].Tf)
    Tf4 = fcnFromString(boundaryConditions[4].Tf)

    #4.初始化温度场
    u0 = zeros(100)
    #5.利用DifferentialEquations求解
    prob = ODEProblem(heat!, u0, (0, time), p, saveat=1)
    sol = solve(prob, Tsit5())
    #6.数值解的规范化
    an_len = length(sol.u)
    res = zeros(n, n, an_len)
    for t in 1:an_len
        for i in 1:n
            for j in 1:n
                res[i, j, t] = sol.u[t][to_index(i, j, n)]
            end
        end
    end
    #7.结束
    return res
end

#3.DifferentialEquations所要求的问题表示函数,dT为一阶导数,T为温度函数,t为时间(自变量),p为常数
#本例相当于把温度场离散化后,将各个格点温度视作时间的一元函数,共同建立一个一阶常微分方程组
#以达到将偏微分方程(热传导方程)化简的目的.完全离散可能存在较大误差,故部分离散后可利用DifferentialEquations
#获得较为精确的解.
function heat!(dT::Vector{Float64}, T::Vector{Float64}, p::Vector{Float64}, t::Float64)
    n = 10
    # 内部节点
    for i in 2:n-1
        for j in 2:n-1
            dT[to_index(i, j, n)] = p[1] * (T[to_index(i + 1, j, n)] + T[to_index(i - 1, j, n)] + T[to_index(i, j + 1, n)] + T[to_index(i, j - 1, n)] - 4 * T[to_index(i, j, n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    # 边边界节点
    #西边
    if boundaryConditions[1].serialNumber == 1
        #第一类边界条件
        bt = fcnFromString(boundaryConditions[1].bt)
        for i in 2:n-1
            T[to_index(i, 1, n)] = bt(t)
        end
    elseif boundaryConditions[1].serialNumber == 2
        #第二类边界条件
        qw = fcnFromString(boundaryConditions[1].qw)
        for i in 2:n-1
            dT[to_index(i, 1, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,2,n)]-T[to_index(i,1,n)]) + p[1]*(T[to_index(i+1,1,n)]-2*T[to_index(i,1,n)]+T[to_index(i-1,1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    elseif boundaryConditions[1].serialNumber == 3
        #第三类边界条件
        for i in 2:n-1
            dT[to_index(i, 1, n)] = 2*p[5]*(Tf1(t)-T[to_index(i,1,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,2,n)]-T[to_index(i,1,n)]) + p[1]*(T[to_index(i+1,1,n)]-2*T[to_index(i,1,n)]+T[to_index(i-1,1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    #东边
    if boundaryConditions[2].serialNumber == 1
        #第一类边界条件
        bt = fcnFromString(boundaryConditions[2].bt)
        for i in 2:n-1
            T[to_index(i, n, n)] = bt(t)
        end
    elseif boundaryConditions[2].serialNumber == 2
        #第二类边界条件
        qw = fcnFromString(boundaryConditions[2].qw)
        for i in 2:n-1
            dT[to_index(i, n, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,n-1,n)]-T[to_index(i,n,n)]) + p[1]*(T[to_index(i+1,n,n)]-2*T[to_index(i,n,n)]+T[to_index(i-1,n,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    elseif boundaryConditions[2].serialNumber == 3
        #第三类边界条件
        for i in 2:n-1
            dT[to_index(i, n, n)] = 2*p[5]*(Tf2(t)-T[to_index(i,n,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,n-1,n)]-T[to_index(i,n,n)]) + p[1]*(T[to_index(i+1,n,n)]-2*T[to_index(i,n,n)]+T[to_index(i-1,n,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    #北边
    if boundaryConditions[3].serialNumber == 1
        #第一类边界条件
        bt = fcnFromString(boundaryConditions[3].bt)
        for i in 2:n-1
            T[to_index(1, i, n)] = bt(t)
        end
    elseif boundaryConditions[3].serialNumber == 2
        #第二类边界条件
        qw = fcnFromString(boundaryConditions[3].qw)
        for i in 2:n-1
            dT[to_index(1, i, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(2,i,n)]-T[to_index(1,i,n)]) + p[1]*(T[to_index(1,i+1,n)]-2*T[to_index(1,i,n)]+T[to_index(1,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    elseif boundaryConditions[3].serialNumber == 3
        #第三类边界条件
        for i in 2:n-1
            dT[to_index(1, i, n)] = 2*p[5]*(Tf3(t)-T[to_index(1,i,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(2,i,n)]-T[to_index(1,i,n)]) + p[1]*(T[to_index(1,i+1,n)]-2*T[to_index(1,i,n)]+T[to_index(1,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    #南边
    if boundaryConditions[4].serialNumber == 1
        #第一类边界条件
        bt = fcnFromString(boundaryConditions[4].bt)
        for i in 2:n-1
            T[to_index(n, i, n)] = bt(t)
        end
    elseif boundaryConditions[4].serialNumber == 2
        #第二类边界条件
        qw = fcnFromString(boundaryConditions[4].qw)
        for i in 2:n-1
            dT[to_index(n, i, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,i,n)]-T[to_index(n,i,n)]) + p[1]*(T[to_index(n,i+1,n)]-2*T[to_index(n,i,n)]+T[to_index(n,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    elseif boundaryConditions[4].serialNumber == 3
        #第三类边界条件
        for i in 2:n-1
            dT[to_index(n, i, n)] = 2*p[5]*(Tf4(t)-T[to_index(n,i,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,i,n)]-T[to_index(n,i,n)]) + p[1]*(T[to_index(n,i+1,n)]-2*T[to_index(n,i,n)]+T[to_index(n,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    # 角边界
    if boundaryConditions[1].serialNumber == 1
        bt1 = fcnFromString(boundaryConditions[1].bt)
        if boundaryConditions[3].serialNumber == 1
            bt2 = fcnFromString(boundaryConditions[3].bt)
            T[to_index(1, 1, n)] = (bt1(t) + bt2(t))/2
        else
            T[to_index(1, 1, n)] = bt1(t)
        end
        if boundaryConditions[4].serialNumber == 1
            bt3 = fcnFromString(boundaryConditions[4].bt)
            T[to_index(n, 1, n)] = (bt1(t) + bt3(t))/2
        else
            T[to_index(n, 1, n)] = bt1(t)
        end
    elseif boundaryConditions[1].serialNumber == 2
        qw1 = fcnFromString(boundaryConditions[3].qw)
        if boundaryConditions[3].serialNumber == 1
            bt2 = fcnFromString(boundaryConditions[3].bt)
            T[to_index(1, 1, n)] = bt2(t)
        elseif boundaryConditions[3].serialNumber == 2
            qw2 = fcnFromString(boundaryConditions[3].qw)
            dT[to_index(1, 1, n)] = 2*(qw1(t) + qw2(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,2,n)]-2*T[to_index(1,1,n)]+T[to_index(2,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[3].serialNumber == 3
            dT[to_index(1, 1, n)] = 2*(qw1(t) + p[5]*(Tf3(t)-T[to_index(1, 1, n)]))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,2,n)]-2*T[to_index(1,1,n)]+T[to_index(2,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
        if boundaryConditions[4].serialNumber == 1
            bt4 = fcnFromString(boundaryConditions[4].bt)
            T[to_index(n, 1, n)] = bt4(t)
        elseif boundaryConditions[4].serialNumber == 2
            qw4 = fcnFromString(boundaryConditions[4].qw)
            dT[to_index(n, 1, n)] = 2*(qw1(t) + qw4(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n,2,n)]-2*T[to_index(n,1,n)]+T[to_index(n-1,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[4].serialNumber == 3
            dT[to_index(n, 1, n)] = 2*(qw1(t) + p[5]*(Tf4(t)-T[to_index(n, 1, n)]))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n,2,n)]-2*T[to_index(n,1,n)]+T[to_index(n-1,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
    elseif boundaryConditions[1].serialNumber == 3
        if boundaryConditions[3].serialNumber == 1
            bt2 = fcnFromString(boundaryConditions[3].bt)
            T[to_index(1, 1, n)] = bt2(t)
        elseif boundaryConditions[3].serialNumber == 2
            qw2 = fcnFromString(boundaryConditions[3].qw)
            dT[to_index(1, 1, n)] = 2*(p[5]*(Tf1(t)-T[to_index(1,1,n)])+qw2(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,2,n)]-2*T[to_index(1,1,n)]+T[to_index(2,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[3].serialNumber == 3
            dT[to_index(1, 1, n)] = 2*p[5]*(Tf1(t)+Tf3(t)-2*T[to_index(1,1,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,2,n)]-2*T[to_index(1,1,n)]+T[to_index(2,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
        if boundaryConditions[4].serialNumber == 1
            bt4 = fcnFromString(boundaryConditions[4].bt)
            T[to_index(n, 1, n)] = bt4(t)
        elseif boundaryConditions[4].serialNumber == 2
            qw4 = fcnFromString(boundaryConditions[4].qw)
            dT[to_index(n, 1, n)] = 2*(p[5]*(Tf1(t)-T[to_index(n,1,n)])+qw4(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n,2,n)]-2*T[to_index(n,1,n)]+T[to_index(n-1,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[4].serialNumber == 3
            dT[to_index(n, 1, n)] = 2*p[5]*(Tf1(t)+Tf4(t)-2*T[to_index(n,1,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n,2,n)]-2*T[to_index(n,1,n)]+T[to_index(n-1,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    if boundaryConditions[2].serialNumber == 1
        bt3 = fcnFromString(boundaryConditions[2].bt)
        if boundaryConditions[4].serialNumber == 1
            bt4 = fcnFromString(boundaryConditions[4].bt)
            T[to_index(n, n, n)] = (bt3(t) + bt4(t))/2
        else
            T[to_index(n, n, n)] = bt3(t)
        end
        if boundaryConditions[3].serialNumber == 1
            bt2 = fcnFromString(boundaryConditions[3].bt)
            T[to_index(1, n, n)] = (bt3(t) + bt2(t))/2
        else
            T[to_index(1, n, n)] = bt3(t)
        end
    elseif boundaryConditions[2].serialNumber == 2
        qw3 = fcnFromString(boundaryConditions[2].qw)
        if boundaryConditions[4].serialNumber == 1
            bt4 = fcnFromString(boundaryConditions[4].bt)
            T[to_index(n, n, n)] = bt4(t)
        elseif boundaryConditions[4].serialNumber == 2
            qw4 = fcnFromString(boundaryConditions[4].qw)
            dT[to_index(n, n, n)] = 2*(qw3(t)+qw4(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,n,n)]-2*T[to_index(n,n,n)]+T[to_index(n,n-1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[4].serialNumber == 3
            dT[to_index(n, n, n)] = 2*(qw3(t)+p[5]*(Tf4(t)-T[to_index(n, n, n)]))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,n,n)]-2*T[to_index(n,n,n)]+T[to_index(n,n-1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
        if boundaryConditions[3].serialNumber == 1
            bt2 = fcnFromString(boundaryConditions[3].bt)
            T[to_index(1, n, n)] = bt2(t)
        elseif boundaryConditions[3].serialNumber == 2
            qw2 = fcnFromString(boundaryConditions[3].qw)    
            dT[to_index(1, n, n)] = 2*(qw3(t)+qw2(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,n-1,n)]-2*T[to_index(1,n,n)]+T[to_index(2,n,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[3].serialNumber == 3
            dT[to_index(1, n, n)] = 2*(qw3(t)+p[5]*(Tf3(t)-T[to_index(1, n, n)]))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,n-1,n)]-2*T[to_index(1,n,n)]+T[to_index(2,n,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
    elseif boundaryConditions[2].serialNumber == 3
        if boundaryConditions[4].serialNumber == 1
            bt4 = fcnFromString(boundaryConditions[4].bt)
            T[to_index(n, n, n)] = bt4(t)
        elseif boundaryConditions[4].serialNumber == 2
            qw4 = fcnFromString(boundaryConditions[4].qw)
            dT[to_index(n, n, n)] = 2*(p[5]*(Tf2(t)-T[to_index(n,n,n)])+qw4)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,n,n)]-2*T[to_index(n,n,n)]+T[to_index(n,n-1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[4].serialNumber == 3
            dT[to_index(n, n, n)] = 2*p[5]*(Tf2(t)+Tf4(t)-2*T[to_index(n,n,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,n,n)]-2*T[to_index(n,n,n)]+T[to_index(n,n-1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
        if boundaryConditions[3].serialNumber == 1
            bt2 = fcnFromString(boundaryConditions[3].bt)
            T[to_index(1, n, n)] = bt2(t)
        elseif boundaryConditions[3].serialNumber == 2
            qw2 = fcnFromString(boundaryConditions[3].qw)
            dT[to_index(1, n, n)] = 2*(p[5]*(Tf2(t)-T[to_index(1,n,n)])+qw2(t))/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,n-1,n)]-2*T[to_index(1,n,n)]+T[to_index(2,n,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[3].serialNumber == 3
            dT[to_index(1, n, n)] = 2*p[5]*(Tf2(t)+Tf3(t)-2*T[to_index(1,n,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,n-1,n)]-2*T[to_index(1,n,n)]+T[to_index(2,n,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
    end
end