function SOC = SOC_update(pso_out, day, SOC)



ess_operation = reshape(pso_out, [g_num_ESS, g_s_period]);
SOC = SOC + 100*sum(ess_operation,2)/g_ESS_capacity';

end