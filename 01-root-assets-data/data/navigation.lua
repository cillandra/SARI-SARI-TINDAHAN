local N={counter={},byId={},shortcuts={}}
local defs={
 {'cash_drawer','Sukli','sukli',200,170,'3'},
 {'timbangan','Timbangan','timbangan',230,170,'4'},
 {'shelf_cabinet','Cabinet','shelves',200,170,'2'},
 {'phone','TindaPay','phone',110,170,'5',2,'wallet'}
}
for i,row in ipairs(defs) do
 local d={id=row[1],label=row[2],view='counter',side=i<=2 and 'left' or 'right',layoutSlot=i,order=i,target=row[3],action='navigate',designSize={w=row[4],h=row[5]},shortcut=row[6],unlock=row[7] or 1,feature=row[8],hint='Open '..row[2],lockedHint=row[8]=='wallet' and 'Bukas sa Araw 2' or nil}
 N.counter[i]=d; N.byId[d.id]=d; N.shortcuts[d.shortcut]=d
end
N.byId.counter={id='counter',target='counter',action='navigate',shortcut='1',unlock=1}
N.shortcuts['1']=N.byId.counter
N.customer={id='customer',view='counter',action='takeOrder'}
N.pause={id='pause',action='pause',rect={x=1169,y=15,w=64,h=70}}
N.ticket={id='ticket',action='ticket',rect={x=1088,y=15,w=64,h=70}}
N.byId.customer=N.customer; N.byId.pause=N.pause; N.byId.ticket=N.ticket
N.pauseControls={
 resume={action='pause',rect={x=439,y=344,w=402,h=57}},
 save_now={action='save',rect={x=439,y=421,w=194,h=53}},
 title={action='navigate_ui',target='menu',rect={x=649,y=421,w=192,h=53}},
 settings={action='pause_panel',panel='settings',rect={x=439,y=482,w=194,h=48}},
 summary={action='pause_panel',panel='summary',rect={x=649,y=482,w=192,h=48}},
 quit={action='pause_panel',panel='quit',rect={x=439,y=543,w=402,h=44}},
 panel_back={action='pause_back',rect={x=439,y=526,w=402,h=48}},
 quit_confirm={action='quit_confirm',rect={x=439,y=454,w=402,h=54}},
 volume_down={action='setting_step',field='volume',delta=-.1,min=0,max=1,rect={x=735,y=258,w=44,h=44}},
 volume_up={action='setting_step',field='volume',delta=.1,min=0,max=1,rect={x=792,y=258,w=44,h=44}},
 difficulty={action='setting_cycle',field='difficulty',values={'easy','normal','hard'},rect={x=716,y=312,w=125,h=44}},
 motion={action='setting_toggle',field='reducedMotion',rect={x=716,y=367,w=125,h=44}},
 text_size={action='setting_cycle',field='textScale',values={1,1.15,1.3},rect={x=716,y=422,w=125,h=44}}
}
for id,d in pairs(N.pauseControls) do d.id=id; d.view='pause'; N.byId[id]=d end
return N
