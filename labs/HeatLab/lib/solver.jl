using DifferentialEquations: ODEProblem, solve, Tsit5

function get_data(T0::Float64, Tout::Float64, time::Float64)
    #1.设置常数
    #1.1热扩散系数
    a = 1.27E-5
    #1.2表征格点个数(x,y方向离散步长相同)
    n = 10
    #1.3板长(正方形板)
    L = 0.2
    #1.4离散步长
    δ = L / n
    #1.5化简方程所得常数与傅里叶数相差一时间,可以看作时间常数
    A = a / δ^2
    #2.索引函数
    function to_index(i, j, n)
        return (i - 1) * n + j
    end
    #3.DifferentialEquations所要求的问题表示函数,dT为一阶导数,T为温度函数,t为时间(自变量),p为常数
    #本例相当于把温度场离散化后,将各个格点温度视作时间的一元函数,共同建立一个一阶常微分方程组
    #以达到将偏微分方程(热传导方程)化简的目的.完全离散可能存在较大误差,故部分离散后可利用DifferentialEquations
    #获得较为精确的解.
    function heat!(dT, T, t, p)
        n = 10
        # 内部节点
        for i in 2:n-1
            for j in 2:n-1
                dT[to_index(i, j, n)] = p * (T[to_index(i + 1, j, n)] + T[to_index(i - 1, j, n)] + T[to_index(i, j + 1, n)] + T[to_index(i, j - 1, n)] - 4 * T[to_index(i, j, n)])
            end
        end
        # 边边界节点
        for i in 2:n-1
            dT[to_index(i, 1, n)] = 0
        end
        for i in 2:n-1
            dT[to_index(i, n, n)] = 0
        end
        for i in 2:n-1
            dT[to_index(1, i, n)] = 0
        end
        for i in 2:n-1
            dT[to_index(n, i, n)] = 0
        end
        # 角边界节点
        dT[to_index(1, 1, n)] = 0
        dT[to_index(n, n, n)] = 0
        dT[to_index(n, 1, n)] = 0
        dT[to_index(1, n, n)] = 0
    end
    #4.初始化温度场
    u0 = zeros(100)
    for j in 1:100
        if j%10 == 1
            u0[j] = T0
        else
            u0[j] = Tout
        end
    end
    #5.利用DifferentialEquations求解
    prob = ODEProblem(heat!, u0, (0, time), A, saveat=1)
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