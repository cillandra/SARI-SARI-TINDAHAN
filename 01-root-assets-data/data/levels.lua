-- Ten teaching days and endless definitions. Money fields use integer centavos.
local Config=require('data.config')
local Levels={list={}}
local chances={.60,.65,.70,.75,.80,.85,.90,.90,.95,.95}
local rows={
 {6,1,Config.patience_max,nil,300,'Unang araw sa tindahan!','Kunin ang item. Sukli = bayad - halaga.'},
 {8,2,Config.patience_max,nil,500,'Bagong serbisyo: TindaPay!','Itugma muna ang transfer. Cash-in: tanggapin ang cash. Cash-out: ibigay ang cash.'},
 {8,2,Config.patience_max,.10,650,'Bagong gawain: timbangan!','Pindutin at hawakan, bitawan sa berde.'},
 {10,3,Config.patience_max,.07,800,'Magbalot tayo ng tingi!','Piliin muna ang laki ng bag, saka buhos.'},
 {10,3,Config.patience_max,.07,1000,'May mantika na!','Bitawan agad bago matapon ang mantika.'},
 {10,3,Config.patience_max,.05,1200,'Mag-ingat sa peke!','Tingnan ang lahat: halaga, ref, tatanggap, status.'},
 {12,3,Config.patience_max,.05,1450,'Umuulan, dagsa ang suki!','Unahin ang madadaling order.'},
 {12,3,Config.patience_max,.05,1700,'Kulang na ang barya!','Ubos na ang barya. Gamitin nang maingat.'},
 {14,4,Config.patience_max,.05,2000,'Payday! Dami ng cash-out!','Bantayan ang cash sa drawer.'},
 {18,4,Config.patience_max,.05,2800,'Fiesta! Lahat ng gawain!','Fiesta! Gamitin ang lahat ng natutunan.'},
}
local function unlocks(day)
 local result={'item'}
 if day>=2 then result[#result+1]='cash_in';result[#result+1]='cash_out' end
 if day>=3 then result[#result+1]='weigh' end
 if day>=4 then result[#result+1]='repack' end
 if day>=5 then result[#result+1]='pour' end
 return result
end
local spotlights={{'item'},{'cash_in','cash_out'},{'weigh'},{'repack'},{'pour'}}
for day,row in ipairs(rows) do
 local bills={2000,5000,10000}
 if day>=2 then bills[#bills+1]=50000 end
 if day>=6 then bills[#bills+1]=100000 end
 Levels.list[day]={day=day,customers=row[1],max_lines=row[2],patience=row[3],tolerance=row[4],goal=row[5]*100,
  unlocks=unlocks(day),spotlight=spotlights[day] or {},tender_bills=bills,change_chance=chances[day],
  scam_chance=day>=6 and .2 or 0,barya_low=day>=8,event=day==7 and 'rain' or day==9 and 'payday' or day==10 and 'fiesta' or nil,
  intro=row[6],tip=row[7],warning=day==8 and 'Bukas: kulang sa barya. Bumili ng barya!' or day==9 and 'Bukas: payday! Maraming cash-out.' or nil}
end
local function copy(value)
 if type(value)~='table' then return value end
 local result={};for key,item in pairs(value) do result[key]=copy(item) end;return result
end
function Levels.get(day)
 assert(type(day)=='number' and day>=1 and day%1==0,'Positive integer day required')
 local result=copy(Levels.list[day])
 if not result then
  result={day=day,customers=18+(day-10),patience=Config.patience_max,goal=(2800+300*(day-10))*100,
   max_lines=4,tolerance=.05,scam_chance=.2,barya_low=true,tender_bills={2000,5000,10000,50000,100000},
   change_chance=.95,unlocks=unlocks(day),spotlight={},intro='Bagong araw, tuloy ang tindahan!',tip='Gamitin ang lahat ng natutunan.'}
  -- Endless event is chosen once by Order.refresh, never by this query.
 end
 result.patience=math.min(result.patience,Config.patience_max)
 return result
end
return Levels
