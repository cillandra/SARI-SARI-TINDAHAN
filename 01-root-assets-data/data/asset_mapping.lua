-- Purpose: user-confirmed M0 copy mapping; originals remain immutable.
local Mapping={list={},byId={}}
local function add(source,id,box,policy,reason)
 local entry={source=source,id=id,sourceBox={x=box[1],y=box[2],w=box[3]-box[1],h=box[4]-box[2]},policy=policy,reason=reason}
 Mapping.list[#Mapping.list+1]=entry; if id then Mapping.byId[id]=entry end
end
add('assets_raw/props/prop_cash_drawer_close.png','prop_cash_drawer',{546,287,2729,2469},'import','Uniform fit; phone branding covered by the frontend')
add('assets_raw/props/prop_cash_drawer_open.png','prop_cash_drawer_open',{464,302,2708,2892},'procedural','source aspect cannot satisfy strict target art box with uniform scaling')
add('assets_raw/props/prop_phone.png','prop_phone',{915,305,2317,2905},'import','Uniform fit; phone branding covered by the frontend')
add('assets_raw/props/prop_shelf_cabinet.png','prop_shelf_cabinet',{703,323,2478,2879},'import','Uniform fit; phone branding covered by the frontend')
add('assets_raw/props/prop_timbangan.png','prop_timbangan',{492,361,2677,2821},'import','Uniform fit; phone branding covered by the frontend')
add('assets_raw/props/prop_utang_notebook.png','prop_utang_notebook',{741,387,2459,2840},'procedural','source aspect cannot satisfy strict target art box with uniform scaling')
add('assets_raw/scenes/scene_counter_bg_interior.png','scene_counter_bg_interior',{0,0,8000,4500},'import','Opaque supplied interior used as the complete painted background')
add('assets_raw/scenes/scene_counter_fg.png','scene_counter_fg',{0,3130,8000,4499},'import','')
add('assets_raw/scenes/scene_counter_windows.png',nil,{0,0,8000,4500},'unassigned','wood image is not a street background; intended use unassigned')
add('assets_raw/character_expression/angry.png','char_nurse_angry',{246,72,2238,3099},'import','')
add('assets_raw/character_expression/char_delivery_driver_angry.png','char_delivery_rider_angry',{290,178,2259,3046},'import','')
add('assets_raw/character_expression/char_delivery_driver_happy.png','char_delivery_rider_happy',{286,196,2257,3046},'import','')
add('assets_raw/character_expression/char_delivery_driver_impatient.png','char_delivery_rider_impatient',{288,196,2261,3046},'import','')
add('assets_raw/character_expression/char_delivery_driver_waiting.png','char_delivery_rider_waiting',{286,196,2257,3046},'import','')
add('assets_raw/character_expression/char_lola_rosary_angry.png','char_lola_rosary_angry',{298,206,2280,3125},'import','')
add('assets_raw/character_expression/char_lola_rosary_happy.png','char_lola_rosary_happy',{377,215,2187,3125},'import','')
add('assets_raw/character_expression/char_lola_rosary_impatient.png','char_lola_rosary_impatient',{375,215,2187,3125},'import','')
add('assets_raw/character_expression/char_lola_rosary_waiting.png','char_lola_rosary_waiting',{375,215,2187,3125},'import','')
add('assets_raw/character_expression/char_nanay_bayong_angry.png','char_nanay_bayong_angry',{216,205,2255,3125},'import','')
add('assets_raw/character_expression/char_nanay_bayong_happy.png','char_nanay_bayong_happy',{294,214,2253,3125},'import','')
add('assets_raw/character_expression/char_nanay_bayong_impatient.png','char_nanay_bayong_impatient',{294,214,2255,3125},'import','')
add('assets_raw/character_expression/char_nanay_bayong_waiting.png','char_nanay_bayong_waiting',{294,214,2255,3125},'import','')
add('assets_raw/character_expression/char_nurse_happy.png','char_nurse_happy',{329,61,2203,3100},'import','')
add('assets_raw/character_expression/char_nurse_impatient.png','char_nurse_impatient',{326,61,2200,3100},'import','')
add('assets_raw/character_expression/char_nurse_waiting.png','char_nurse_waiting',{305,61,2179,3100},'import','')
add('assets_raw/character_expression/char_school_kid_angry.png','char_school_kid_angry',{246,193,2292,3115},'import','')
add('assets_raw/character_expression/char_school_kid_happy.png','char_school_kid_happy',{342,209,2211,3116},'import','')
add('assets_raw/character_expression/char_school_kid_impatient.png','char_school_kid_impatient',{345,209,2212,3116},'import','')
add('assets_raw/character_expression/char_school_kid_waiting.png','char_school_kid_waiting',{342,209,2210,3116},'import','')
add('assets_raw/character_expression/char_tambay_angry.png','char_tambay_angry',{214,213,2236,3082},'import','')
add('assets_raw/character_expression/char_tambay_happy.png','char_tambay_happy',{264,221,2236,3082},'import','')
add('assets_raw/character_expression/char_tambay_impatient.png','char_tambay_impatient',{264,204,2242,3066},'import','')
add('assets_raw/character_expression/char_tambay_waiting.png','char_tambay_waiting',{264,220,2244,3082},'import','')
add('assets_raw/character_expression/char_teacher_angry.png','char_teacher_angry',{311,217,2301,3125},'import','')
add('assets_raw/character_expression/char_teacher_happy.png','char_teacher_happy',{445,221,2196,3125},'import','')
add('assets_raw/character_expression/char_teacher_impatient.png','char_teacher_impatient',{445,221,2198,3125},'import','')
add('assets_raw/character_expression/char_teacher_waiting.png','char_teacher_waiting',{441,221,2197,3125},'import','')
add('assets_raw/character_expression/char_tricycle_driver_happy (2).png','char_tricycle_driver_waiting',{294,211,2251,3067},'import','')
add('assets_raw/character_expression/char_tricycle_driver_happy (3).png','char_tricycle_driver_impatient',{294,212,2251,3067},'import','')
add('assets_raw/character_expression/char_tricycle_driver_happy (4).png','char_tricycle_driver_angry',{274,212,2265,3067},'import','')
add('assets_raw/character_expression/char_tricycle_driver_happy.png','char_tricycle_driver_happy',{294,212,2251,3067},'import','')
local largest={}
for _,entry in ipairs(Mapping.list) do
 if entry.policy=="import" and entry.id:sub(1,5)=="char_" then
  local family=entry.id:match("^char_(.+)_[^_]+$"); entry.family=family
  local box=largest[family] or {w=0,h=0}; largest[family]=box
  box.w=math.max(box.w,entry.sourceBox.w); box.h=math.max(box.h,entry.sourceBox.h)
 end
end
for _,entry in ipairs(Mapping.list) do
 if entry.family then local box=largest[entry.family]; entry.scale=math.min(800/box.w,1000/box.h)
 elseif entry.id=="scene_counter_fg" then entry.scale=math.min(2560/entry.sourceBox.w,500/entry.sourceBox.h) end
end
return Mapping
