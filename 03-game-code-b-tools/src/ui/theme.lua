-- Purpose: canonical reference palette with compatible aliases. API: named normalized RGBA tables. Dependencies: none.
local function hex(value) return {tonumber(value:sub(1,2),16)/255,tonumber(value:sub(3,4),16)/255,tonumber(value:sub(5,6),16)/255,1} end
local T={paper=hex('FBEFD9'),blush=hex('F3D3CB'),dustyrose=hex('D98E8A'),maroon=hex('7E3A36'),ink=hex('5A3A32'),wood=hex('C99366'),darkwood=hex('9A6A45'),steel=hex('8C9AAE'),bininner=hex('5F6779'),sage=hex('A9B88B'),teal=hex('7FA6A0'),mustard=hex('E9B44C'),sky=hex('CFD9DD'),floor=hex('8FA0D0'),plum=hex('6B5470'),white={1,1,1,1}}
T.propOutline=hex('4A2E26'); T.cream=T.paper; T.rose=T.dustyrose; T.lightwood=T.wood; T.mint=T.sage; T.linebrown=T.ink; T.hudmaroon=T.maroon; T.binsteel=T.steel; T.inner=T.bininner; T.dustyteal=T.teal; T.periwinklefloor=T.floor; T.plumshadow=T.plum
T.skinTones={hex('FFE2C8'),hex('F4D2B6'),hex('E6B798'),hex('DDA385'),hex('C88A6C'),hex('B8785A'),hex('95634D'),hex('70483D')}
return T

