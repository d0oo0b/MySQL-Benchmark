#!/usr/bin/env sysbench
-- Copyright Shen Hong


require("aurora_rr_common")


function event()
   if not sysbench.opt.skip_trx then
      begin()
   end


   execute_batch_insert()

   if not sysbench.opt.skip_trx then
      commit()
   end
end


function prepare_statements()

   if not sysbench.opt.skip_trx then
      prepare_begin()
      prepare_commit()
   end
   
   prepare_batch_insert()
--   if sysbench.opt.range_selects then
--      prepare_simple_ranges()
--      prepare_sum_ranges()
--      prepare_order_ranges()
--      prepare_distinct_ranges()
--   end
end
