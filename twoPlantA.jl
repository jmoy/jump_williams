using JuMP, HiGHS,Printf

model = Model(HiGHS.Optimizer)

@variable(model,StdA>=0)
@variable(model,DlxA>=0)
@variable(model,StdB>=0)
@variable(model,DlxB>=0)

#Grinding constraint factory A
@constraint(model,4StdA+2DlxA<=80)

#Polishing constraint factory A
@constraint(model,2StdA+5DlxA<=60)

#Grinding constraint factory B
@constraint(model,5StdB+3DlxB<=60)

#Polishing constraint factory B
@constraint(model,5StdB+6DlxB<=75)

#Raw material constraint
@constraint(model,cons_rawM,4(StdA+StdB+DlxA+DlxB)<=120)

@objective(model,Max,10(StdA+StdB)+15(DlxA+DlxB))

optimize!(model)

solution_summary(model)

@printf("%.6g\n",objective_value(model))
@printf("%.2g, %.2g, %.2g, %.2g\n",value(StdA),value(StdB),value(DlxA),value(DlxB))