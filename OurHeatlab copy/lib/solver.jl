using DifferentialEquations: ODEProblem, solve, Tsit5

function get_data(T0::Float64, Tout::Float64, time::Float64)
    #1.设置常数及边界条件
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

    #1.6设置边界条件
    boundaryConditions = 2*ones(4)
    #1.6.1设置内热源
    internalHeatSource(t) = 0
    #1.6.2设置边界温度
    bt(t) = 1000*cos(t)
    #1.6.3设置边界热流密度
    qw(t) = 5
    #1.6.4设置流体温度
    Tf(t) = 500

    #2.索引函数
    function to_index(i, j, n)
        return (i - 1) * n + j
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
        for i in 2:n-1
            if boundaryConditions[1] == 1
                #第一类边界条件
                dT[to_index(i, 1, n)] = bt(t)
            elseif boundaryConditions[1] == 2
                #第二类边界条件
                dT[to_index(i, 1, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,2,n)]-T[to_index(i,1,n)]) + p[1]*(T[to_index(i+1,1,n)]-2*T[to_index(i,1,n)]+T[to_index(i-1,1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            elseif boundaryConditions[1] == 3
                #第三类边界条件
                dT[to_index(i, 1, n)] = 2*p[5]*(Tf(t)-T[to_index(i,1,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,2,n)]-T[to_index(i,1,n)]) + p[1]*(T[to_index(i+1,1,n)]-2*T[to_index(i,1,n)]+T[to_index(i-1,1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            end
        end
        #东边
        for i in 2:n-1
            if boundaryConditions[2] == 1
                #第一类边界条件
                dT[to_index(i, n, n)] = bt(t)
            elseif boundaryConditions[2] == 2
                #第二类边界条件
                dT[to_index(i, n, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,n-1,n)]-T[to_index(i,n,n)]) + p[1]*(T[to_index(i+1,n,n)]-2*T[to_index(i,n,n)]+T[to_index(i-1,n,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            elseif boundaryConditions[2] == 3
                #第三类边界条件
                dT[to_index(i, n, n)] = 2*p[5]*(Tf(t)-T[to_index(i,n,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(i,n-1,n)]-T[to_index(i,n,n)]) + p[1]*(T[to_index(i+1,n,n)]-2*T[to_index(i,n,n)]+T[to_index(i-1,n,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
    
            end
        end
        #北边
        for i in 2:n-1
            if boundaryConditions[3] == 1
                #第一类边界条件
                dT[to_index(1, i, n)] = bt(t)
            elseif boundaryConditions[3] == 2
                #第二类边界条件
                dT[to_index(1, i, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(2,i,n)]-T[to_index(1,i,n)]) + p[1]*(T[to_index(1,i+1,n)]-2*T[to_index(1,i,n)]+T[to_index(1,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            elseif boundaryConditions[3] == 3
                #第三类边界条件
                dT[to_index(1, i, n)] = 2*p[5]*(Tf(t)-T[to_index(1,i,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(2,i,n)]-T[to_index(1,i,n)]) + p[1]*(T[to_index(1,i+1,n)]-2*T[to_index(1,i,n)]+T[to_index(1,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            end
        end
        #南边
        for i in 2:n-1
            if boundaryConditions[4] == 1
                #第一类边界条件
                dT[to_index(n, i, n)] = bt(t)
            elseif boundaryConditions[4] == 2
                #第二类边界条件
                dT[to_index(n, i, n)] = 2*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,i,n)]-T[to_index(n,i,n)]) + p[1]*(T[to_index(n,i+1,n)]-2*T[to_index(n,i,n)]+T[to_index(n,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            elseif boundaryConditions[4] == 3
                #第三类边界条件
                dT[to_index(n, i, n)] = 2*p[5]*(Tf(t)-T[to_index(n,i,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,i,n)]-T[to_index(n,i,n)]) + p[1]*(T[to_index(n,i+1,n)]-2*T[to_index(n,i,n)]+T[to_index(n,i-1,n)])/2 + internalHeatSource(t)/(p[2]*p[3])
            end
        end
        # 角边界(两组角由东西边界分别占有)
        if boundaryConditions[1] == 1
            dT[to_index(1, 1, n)] = bt(t)
            dT[to_index(n, 1, n)] = bt(t)
        elseif boundaryConditions[1] == 2
            dT[to_index(1, 1, n)] = 4*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,2,n)]-2*T[to_index(1,1,n)]+T[to_index(2,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
            dT[to_index(n, 1, n)] = 4*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n,2,n)]-2*T[to_index(n,1,n)]+T[to_index(n-1,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[1] == 3
            dT[to_index(1, 1, n)] = 4*p[5]*(Tf(t)-T[to_index(1,1,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,2,n)]-2*T[to_index(1,1,n)]+T[to_index(2,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
            dT[to_index(n, 1, n)] = 4*p[5]*(Tf(t)-T[to_index(n,1,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n,2,n)]-2*T[to_index(n,1,n)]+T[to_index(n-1,1,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
        if boundaryConditions[3] == 1
            dT[to_index(n, n, n)] = bt(t)
            dT[to_index(1, n, n)] = bt(t)
        elseif boundaryConditions[3] == 2
            dT[to_index(n, n, n)] = 4*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,n,n)]-2*T[to_index(n,n,n)]+T[to_index(n,n-1,n)]) + internalHeatSource(t)/(p[2]*p[3])
            dT[to_index(1, n, n)] = 4*qw(t)/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,n-1,n)]-2*T[to_index(1,n,n)]+T[to_index(2,n,n)]) + internalHeatSource(t)/(p[2]*p[3])
        elseif boundaryConditions[3] == 3
            dT[to_index(n, n, n)] = 4*p[5]*(Tf(t)-T[to_index(n,n,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(n-1,n,n)]-2*T[to_index(n,n,n)]+T[to_index(n,n-1,n)]) + internalHeatSource(t)/(p[2]*p[3])
            dT[to_index(1, n, n)] = 4*p[5]*(Tf(t)-T[to_index(1,n,n)])/(p[2]*p[3]*p[4]) + p[1]*(T[to_index(1,n-1,n)]-2*T[to_index(1,n,n)]+T[to_index(2,n,n)]) + internalHeatSource(t)/(p[2]*p[3])
        end
    end
    #4.初始化温度场
    u0 = zeros(100)
    for j in 1:100
        if j%10 == 1
            u0[j] = 0
        else
            u0[j] = Tout
        end
    end
    #5.利用DifferentialEquations求解
    prob = ODEProblem(heat!, u0, (0, time), [A,density,c,δ,h], saveat=1)
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