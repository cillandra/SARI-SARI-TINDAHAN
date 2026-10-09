-- Purpose: rice/loose-goods station. API: draw(app). Dependencies: shared measurement view.
local M=require('src.views.measurement'); return {draw=function(a) M.draw(a,false) end}

