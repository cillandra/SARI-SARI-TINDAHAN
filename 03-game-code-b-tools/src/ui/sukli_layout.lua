-- Design-canvas geometry only; denomination values are integer centavos.
local L={receipt={x=32,y=137,w=277,h=455},drawer={x=326,y=137,w=656,h=455},tray={x=999,y=234,w=249,h=278},bills={2000,5000,10000,50000,100000},coins={100,500,1000},slots={},controls={back={x=32,y=642,w=178,h=48},cancel={x=224,y=642,w=178,h=48},receive={x=48,y=529,w=245,h=48},undo={x=343,y=535,w=618,h=48},confirm={x=999,y=535,w=249,h=57}}}
for i,d in ipairs(L.bills) do L.slots[d]={x=343+(i-1)*125,y=158,w=117,h=183} end
for i,d in ipairs(L.coins) do L.slots[d]={x=343+(i-1)*209,y=365,w=200,h=148} end
return L
