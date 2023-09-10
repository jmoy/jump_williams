using JuMP,HiGHS

#Time slots in the day
NSlots = 5
SlotLengths = [6,3,6,3,6] #Hours in each time slot

#Generator types
NTypes = 3

#Base power requirements
PowerReq = [15000, 30000, 25000, 40000, 27000]

#Extra power requirement as a percentage
ExtraPowerReq = 0.15

#Generator characteristics
GNo = [12,10,5]  #Nos available
GMinimumCap = [850,1250,1500] #Minimum Capicity
GMaximumCap = [2000,1750,4000] #Maximum Capacity
GFixedCost = [1000,2600,3000] #Fixed cost of operation at minimum capacity per hour
GVarCost = [2,1.3,3] #Variable cost per megawatt hour above minimum
GStartCost = [2000,1000,500] #Generator startup cost

model = Model(HiGHS.Optimizer)

#Number of active generators
@variable(model,nactive[i=1:NSlots,j=1:NTypes]>=0,Int)

#No of generators newly started
@variable(model,nstarted[i=1:NSlots,j=1:NTypes]>=0,Int)

#Pinning down nstarted
#The weird expression (NSlots+i-2)%NSlots+1 is the 
#  index of previous slot, with the slot previous to 5
#  being 1 as the day wraps around
@constraint(model,active_start[i=1:NSlots,j=1:NTypes],
            nactive[(NSlots+i-2)%NSlots+1,j] + nstarted[i,j] >= nactive[i,j])

#Number of generators constraint
@constraint(model,ngens[i=1:NSlots,j=1:NTypes],
                    nactive[i,j] <= GNo[j])

#Load above minimum load
@variable(model,extraload[i=1:NSlots,j=1:NTypes]>=0)

#Available power
@expression(model,power_avail[i=1:NSlots,j=1:NTypes],
                    nactive[i,j] * GMinimumCap[j] + extraload[i,j])

#Max power
@expression(model,power_max[i=1:NSlots,j=1:NTypes],nactive[i,j] * GMaximumCap[j])

#Constraint, available power must be less than max capacity
@constraint(model,cpower_lim[i=1:NSlots,j=1:NTypes],power_avail[i,j]<=power_max[i,j])

#Constraint, available power must meet base need
@constraint(model,cpower_base[i=1:NSlots],
                sum(power_avail[i,:])>=PowerReq[i])

#Constraint, max power must meed surge need
@constraint(model,cpower_surge[i=1:NSlots],
                    sum(power_max[i,:])>=(1+ExtraPowerReq) .* PowerReq[i])

#Cost, fixed and variable, per slot,per_type
@expression(model,running_cost[i=1:NSlots,j=1:NTypes],
            SlotLengths[i]*(GFixedCost[j]*nactive[i,j]+extraload[i,j]*GVarCost[j]))

#Startup cost, per slot, type
@expression(model,start_cost[i=1:NSlots,j=1:NTypes],
                                nstarted[i,j] * GStartCost[j])

#objective
@objective(model,Min,sum(running_cost)+sum(start_cost))

#solve
optimize!(model)
