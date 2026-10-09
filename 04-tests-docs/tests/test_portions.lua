return function()
 local S=require('src.model.state')
 local P=require('src.systems.portions')
 local R=require('src.systems.retail')
 local I=require('src.systems.inventory')
 local s=S.new(1); s.phase='service'
 assert(R.begin(s,'rice')); assert(P.target(s,'rice','rice_regular',1000,'quantity'))
 assert(R.quote(s,'rice').total==5500)
 assert(not R.stageTender(s,'rice',{[10000]=1}))
 assert(P.adjust(s,'rice',1,999)); assert(not P.confirm(s,'rice',1))
 assert(P.adjust(s,'rice',1,1100)); assert(P.confirm(s,'rice',1)); assert(not P.confirm(s,'rice',1))
 assert(R.stageTender(s,'rice',{[10000]=1})); assert(R.commit(s,'rice',{[1000]=4,[500]=1}))
 assert(s.ledger.costOfGoods==4950 and s.ledger.retailRevenue==5500 and I.available(s,'rice_regular')==3900)
 assert(R.begin(s,'peso')); assert(P.target(s,'peso','rice_regular',1000,'peso'))
 local l=s.retail.lines[1]; assert(l.targetQuantity==182 and l.amount==1000)
 assert(P.adjust(s,'peso',1,182)); assert(P.confirm(s,'peso',1)); assert(R.cancel(s,'peso'))
 assert(I.available(s,'rice_regular')==3900)
 s=S.new(2); local original=I.available(s,'cooking_oil'); local cost=s.inventory.cooking_oil[1].totalCost
 assert(P.prepack(s,'pack1','cooking_oil',250)); assert(not P.prepack(s,'pack1','cooking_oil',250))
 assert(I.available(s,'cooking_oil')==original)
 local sum=0; local found=false
 for _,b in ipairs(s.inventory.cooking_oil) do sum=sum+b.totalCost; if b.prepared then found=true; assert(b.quantity==250 and b.receivedDay==1 and b.expiresDay==181) end end
 assert(sum==cost and found)
 s.phase='service'; assert(R.begin(s,'spill')); assert(P.target(s,'spill','sugar',250,'quantity')); assert(P.adjust(s,'spill',1,300,true)); assert(R.cancel(s,'spill'))
  assert(I.available(s,'sugar')==1700 and s.ledger.spoilage==1920)
 s=S.new(3); s.inventory.cooking_oil={{id='old',quantity=500,totalCost=4000,receivedDay=1,expiresDay=20,prepared=false},{id='new',quantity=500,totalCost=5000,receivedDay=2,expiresDay=30,prepared=false}}
 assert(P.prepack(s,'fifo','cooking_oil',250)); assert(I.reserve(s,'consume','cooking_oil',500)); local ok,c=I.consume(s,'consume'); assert(ok and c==4000,'prepack preserves original FIFO cost order')
 s=S.new(4); s.phase='service'; assert(R.begin(s,'opened')); assert(P.target(s,'opened','sugar',250)); assert(P.adjust(s,'opened',1,300,true)); assert(not R.remove(s,'opened',1),'opened contents cannot bypass discard')
 s.ledger.spoilage=9007199254740900; local available=I.available(s,'sugar'); assert(not R.cancel(s,'opened')); assert(s.retail and I.available(s,'sugar')==available,'overflow discard is atomic')
end

