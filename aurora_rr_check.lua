#!/usr/bin/env sysbench
-- Copyright (C) Shen Hong

require("aurora_rr_common")


function event()
--	if pcall(function()

		   if not sysbench.opt.skip_trx then
		      begin()
		   end


		   for table_num = 1, sysbench.opt.tables do 
		       
			rs  = con:query(string.format([[SELECT max(id) 
							  FROM sbtest%d
						      ]],table_num))
			os.execute("sleep " .. 0.01)
			for i = 1, rs.nrows do
			    row = rs:fetch_row()
			    if row[1] ~= nil then
			       local num = 0 
			       num = tonumber(row[1])
			       rscount = con:query(string.format([[SELECT count(id) 
								     FROM sbtest%d
								    where id > %d ]],table_num, num))
			       row_count = rscount:fetch_row()
			       local num_count = 0
			       num_count = tonumber(row_count[1])
			       local num1,num2=math.modf(num/sysbench.opt.batch_inserts)
			       -- print("+++++++++++++ num_count is "..num_count)
			       if num2~=0 then
				  print("xxxxxxxxxxx  %d    xxxxxxxxxxxx", num1)
				  print(string.format("Max of table sbtest%d is  %d ", table_num, num))
			       end
			       --con:query(string.format([[update sbtest%d set c = 1 where id <= %d and c = 0
			       --                         ]],table_num, num))
			    end
		       end
		    end


		   if not sysbench.opt.skip_trx then
		      commit()
		   end
--	   end)
--	then
		-- no error
--	else
		-- close_statements()
--		pcall(function()
--			prepare_statements()
--		      end)
		
--	end
end


function prepare_statements()
--   prepare_point_selects()

   if not sysbench.opt.skip_trx then
      prepare_begin()
      prepare_commit()
   end

--   if sysbench.opt.range_selects then
--      prepare_simple_ranges()
--      prepare_sum_ranges()
--      prepare_order_ranges()
--      prepare_distinct_ranges()
--   end
end
