--  *************************************************************************
--  * Dies ist ein Skript zur Auswertung, das für die Maturaarbeit 2014/15  *
--  *                  von Simon Studer entwickelt wurde.                   *
--  *   Es ist zum Zeitpunkt der Abgabe (5.1.2015) die finale Version zum   *
--  *   Programm und wird in Zukunft verbessert oder verändert im Ordner    *
--  *                             /postRelease/                             *
--  *                             aktualisiert.                             *
--  *************************************************************************

-- Dieses Skript wird auf einem Computer mit Lua for Windows oder ähnlichem ausgeführt und muss sich im gleichen Ordner wie die kopierten Ausgabedateien von airodump-ng befinden.
-- Es wird im demselben Ordner eine Auswertungsdatei Overview.csv erstellt


-- change




-- functions ------------------------------------------------------------------------
function sleep(n)
local t0 = os.clock()
while os.clock() - t0 <= n do end
end

function scandir(directory)
local i, t, popen = 0, {}, io.popen
for filename in popen('dir "'..directory..'" /b '):lines() do
i = i + 1
t[i] = filename
end
return t
end

function unify(nbr)
nbr=tostring(nbr)
while #nbr<2 do
nbr="0"..nbr
end
return nbr
end

function ins(sstring,swhat,sind)
sbefore=string.sub(sstring,1,sind-1)..""
safter=string.sub(sstring,sind)..""
sstring=sbefore..swhat..safter
return sstring
end

function insSpalte(sline,swhat,sind)
_,sps=string.gsub(sline,",",",")
while sps<sind do
sline=sline..","
_,sps=string.gsub(sline,",",",")
end
sbefore=""
for i=2,sind do
sbefore=sbefore..string.sub(sline,1,string.find(sline,","))..""
sline=string.sub(sline,string.find(sline,",")+1)..""
end
safter=sline
return sbefore..swhat..","..safter
end

function replSpalte(sline,swhat,sind)
if sline==nil then sline="" end
_,sps=string.gsub(sline,",",",")
while sps<sind do
sline=sline..","
_,sps=string.gsub(sline,",",",")
end
sbefore=""
for i=2,sind do
sbefore=sbefore..string.sub(sline,1,string.find(sline,","))..""
sline=string.sub(sline,string.find(sline,",")+1)..""
end
safter=string.sub(sline,string.find(sline,",")+1)..""
return sbefore..swhat..","..safter
end

function readSpalte(sline,sind)
_,sps=string.gsub(sline,",",",")
if sps==nil then sps=0 end
if sps>=sind then

for i=2,sind do
sline=string.sub(sline,string.find(sline,",")+1)..""
end
sread=string.sub(sline,1,string.find(sline,",")-1)..""

if sread~=nil then
return sread
else
return " "
end
else
return " "
end
end

function searchSpalte(sline,swhat)
	local d=string.sub(sline,1,string.find(sline,swhat))..""
	local _,sind=string.gsub(d,",",",")
	sind=sind+1
	return sind
end

function clearFile(spath)
f=io.input(spath)
txt=f:read("*a")
tmptxt=""
for b in string.gmatch(txt,".") do
if string.byte(b)==0 then 
tmptxt=tmptxt.." "
else
tmptxt=tmptxt..b
end
end
io.output(spath)
for b in string.gmatch(tmptxt,".") do
io.write(b)
end
io.close()
end

function num2hex(num)
    local hexstr = '0123456789ABCDEF'
    local s = ''
    while num > 0 do
        local mod = math.fmod(num, 16)
        s = string.sub(hexstr, mod+1, mod+1) .. s
        num = math.floor(num / 16)
    end
    if s == '' then s = '0' end
    return s
end

function hex2num(snr)
	local d=string.gsub(snr,":","")
	d=tonumber(d,16)
	return d
end

function num2mac(num)
	local d=num2hex(num)
	d=tostring(d)
	while #d<12 do
		d="0"..d
	end
	d=string.sub(d,1,2)..":"..string.sub(d,3,4)..":"..string.sub(d,5,6)..":"..string.sub(d,7,8)..":"..string.sub(d,9,10)..":"..string.sub(d,11,12)
	return d
end


-- list of outputFiles in allFiles ----------------------------------------------------
cD=arg[0]
cD=string.reverse(cD)
cD=string.sub(cD,string.find(cD,"\\")+1)..""
cD=string.reverse(cD)
cD=cD.."/"
cD=string.gsub(cD,"\\","/")
print(cD)
tmpAllFiles=scandir(cD)
allFiles={}
for i,v in pairs(tmpAllFiles) do
	if string.find(v,"outputFile") then
	table.insert(allFiles,v)
	end
end   
sleep(1)

-- getting timespan --------------------------------------------------------------------
firstOutput=allFiles[1]
lastOutput=allFiles[#allFiles]
startingTime=tonumber(string.sub(firstOutput,12,21).."")
endingTime=tonumber(string.sub(lastOutput,12,21).."")
dStart=os.date("*t",startingTime)
dEnde=os.date("*t",endingTime)

-- starting file -----------------------------------------------------------------------
overview={}
overview[1]="Analyse,von "..dStart.day.."."..dStart.month..". "..dStart.year.." "..unify(dStart.hour)..":"..unify(dStart.min).."."..unify(dStart.sec)..","
overview[2]=",bis "..dEnde.day.."."..dEnde.month..". "..dEnde.year.." "..unify(dEnde.hour)..":"..unify(dEnde.min).."."..unify(dEnde.sec)..","
overview[3]=",aps,,clients,,stop,"
overview[4]=",macs,,macs,,stop,"
overview[5]=",name,,name,,stop,"
overview[6]=",privacy,,probed wlans,,stop,"
overview[7]=",channel,,,,stop,"
overview[8]=","
overview[9]=","
overview[10]="timestamp,"
overview[11]=",#beacons,    ,#packets,"
overview[12]=",#allbeacons, ,#allpackets,"
overview[13]=",,            ,connectedTo(bssid),"
overview[14]=","


-- alle Fileinhalte und daten in allFiles einfügen --------------------------------------
tmpallFiles=allFiles
print("start")
allFiles={}
nextFileStart=0
for filenr,filename in pairs(tmpallFiles) do --vorbereiten
	print(filenr.." / "..#allFiles)
	tmpTable={}
	tmpTable["t"]=tonumber(string.sub(filename,12,21).."")
	fileEndTime=tonumber(tmpTable.t)
	fileStartTime=nextFileStart
	nextFileStart=fileEndTime
	d=os.date("*t",tmpTable.t)
	tmpTable["sec"]=d.sec
	tmpTable["min"]=d.min
	tmpTable["hour"]=d.hour
	tmpTable["day"]=d.day
	tmpTable["month"]=d.month
	tmpTable["year"]=d.year
	tmpTable["filename"]=filename
	tmpTable["endTime"]=fileEndTime
	tmpTable["startTime"]=fileStartTime
	tmpTable["aptable"]={}
	tmpTable["clitable"]={}
	allFiles[filenr]=tmpTable
	tmpTable={}
	clearFile(cD..filename)	
	for line in io.lines(cD..filename) do
		line=string.gsub(line," ","")
			table.insert(tmpTable,line)
	end
	allFiles[filenr]["inhalt"]=tmpTable
end
print("check")
print(#allFiles)
sleep(2)

for nr,tbl in pairs(allFiles) do --alle informationen in allfiles einfügen
	if tbl.aptable==nil then print("noaptable") tbl["aptable"]={} end
	if tbl.clitable==nil then print("noclitable") tbl["clitable"]={} end

	print(nr.." / "..#allFiles)
	for zeile,zeileninhalt in pairs(tbl.inhalt) do
		if string.find(string.sub(zeileninhalt,1,20),"BSSID") then apzeile=zeile sleep(0.3)
		elseif string.find(string.sub(zeileninhalt,1,20),"Station") then clizeile=zeile sleep(0.3)
		elseif zeile==#tbl.inhalt then stopzeile=zeile
		end
	end
	
	for zeile,zeileninhalt in pairs(tbl.inhalt) do
		neu=1
		for i,v in pairs(allFiles[nr]["aptable"]) do
			if readSpalte(zeileninhalt,1)==v.mac then neu=0 end
		end
		for i,v in pairs(allFiles[nr]["clitable"]) do
			if readSpalte(zeileninhalt,1)==v.mac then neu=0 end
		end
		if zeile>apzeile and zeile<clizeile-1 and neu==1 then
			tmpApTbl={}
			tmpApTbl["mac"]=readSpalte(zeileninhalt,1)
			last=readSpalte(zeileninhalt,3)
			d={}
			d.year=tonumber(string.sub(last,1,string.find(last,"-")-1))
			last=string.sub(last,string.find(last,"-")+1)..""
			d.month=tonumber(string.sub(last,1,string.find(last,"-")-1))
			last=string.sub(last,string.find(last,"-")+1)..""
			d.day=tonumber(string.sub(last,1,2))
			last=string.sub(last,3)..""
			d.hour=tonumber(string.sub(last,1,string.find(last,":")-1))
			last=string.sub(last,string.find(last,":")+1)..""
			d.min=tonumber(string.sub(last,1,string.find(last,":")-1))
			last=string.sub(last,string.find(last,":")+1)..""
			d.sec=tonumber(last)
			lastTime=os.time{year=d.year, month=d.month, day=d.day, hour=d.hour, min=d.min, sec=d.sec}
			if allFiles[nr]["startTime"]==nil or lastTime>tonumber(allFiles[nr]["startTime"]) then
				tmpApTbl["active"]=1
			else
				tmpApTbl["active"]=0
			end
			tmpApTbl["last"]=readSpalte(zeileninhalt,3)
			tmpApTbl["channel"]=readSpalte(zeileninhalt,4)
			tmpApTbl["privacy"]=readSpalte(zeileninhalt,6).." - "..readSpalte(zeileninhalt,8)
			tmpApTbl["beacons"]=readSpalte(zeileninhalt,10)
			tmpApTbl["name"]=readSpalte(zeileninhalt,14)
			table.insert(allFiles[nr]["aptable"],tmpApTbl)
		elseif zeile>clizeile and zeile<stopzeile and neu==1 then
			tmpCliTbl={}
			tmpCliTbl["mac"]=readSpalte(zeileninhalt,1)
			last=readSpalte(zeileninhalt,3)
			d={}
			d.year=tonumber(string.sub(last,1,4))
			last=string.sub(last,6)..""
			d.month=tonumber(string.sub(last,1,2))
			last=string.sub(last,4)..""
			d.day=tonumber(string.sub(last,1,2))
			last=string.sub(last,3)..""
			d.hour=tonumber(string.sub(last,1,2))
			last=string.sub(last,4)..""
			d.min=tonumber(string.sub(last,1,2))
			last=string.sub(last,4)..""
			d.sec=tonumber(last)
			lastTime=os.time{year=d.year, month=d.month, day=d.day, hour=d.hour, min=d.min, sec=d.sec}
			--print(d.year,d.month,d.day,d.hour,d.min,d.sec,zeile,nr)
			if allFiles[nr]["startTime"]==nil or lastTime>tonumber(allFiles[nr]["startTime"]) then 
				tmpCliTbl["active"]=1
			else
				tmpCliTbl["active"]=0
			end
			tmpCliTbl["last"]=readSpalte(zeileninhalt,3)
			tmpCliTbl["packets"]=readSpalte(zeileninhalt,5)
			tmpCliTbl["connected"]=readSpalte(zeileninhalt,6)
			_,probeds=string.gsub(zeileninhalt,",",",")
			probeds=tonumber(probeds)-6
			for i=1,probeds,1 do
				tmpCliTbl["probed"..i]=readSpalte(zeileninhalt,i+6)
			end
			table.insert(allFiles[nr]["clitable"],tmpCliTbl)
		end
	end
end
print("check2")

-- alle aps und clients in overview eintragen ------------------------------------------

macs=4
name=5
priv=6
prob=6
ch=7

apsp=2
clisp=4
stopsp=6

for apNr,apTbl in pairs(allFiles[#allFiles]["aptable"]) do
	for i,v in pairs(overview) do
		overview[i]=insSpalte(overview[i]," ",clisp-1)
	end
	overview[macs]=replSpalte(overview[macs],apTbl.mac,clisp-1)
	overview[name]=replSpalte(overview[name],apTbl.name,clisp-1)
	overview[priv]=replSpalte(overview[priv],apTbl.privacy,clisp-1)
	overview[ch]=replSpalte(overview[ch],apTbl.channel,clisp-1)
	clisp=clisp+1
	stopsp=stopsp+1
end

for cliNr,cliTbl in pairs(allFiles[#allFiles]["clitable"]) do
	for i,v in pairs(overview) do
		overview[i]=insSpalte(overview[i],"",stopsp-1)
	end
	overview[macs]=replSpalte(overview[macs],cliTbl.mac,stopsp-1)
	probeds=""
	for i,v in pairs(cliTbl) do
		if string.find(i,"probed") then
			probeds=probeds.."| "..v.." |"
		end
	end
	overview[prob]=replSpalte(overview[prob],probeds,stopsp-1)
	stopsp=stopsp+1
end

print("check3")
sleep(1)
-- durch alle files durch iterieren und neues einfügen ---------------------------------
apTable={}
cliTable={}
for i=14,10+#allFiles*3 do
	overview[i]=","
end

print("ckeck4")
for nr,tbl in pairs(allFiles) do
	print(nr.." / "..#allFiles)
	if tbl.aptable then print("aptable") else print("noaptable") end
	tmpApTable=tbl.aptable
	tmpCliTable=tbl.clitable
	overview[11+(nr-1)*3]=replSpalte(overview[11+(nr-1)*3],unify(tbl.hour)..":"..unify(tbl.min).."  "..tbl.day.."."..tbl.month.."."..tbl.year,1)
	for i,v in ipairs(allFiles[#allFiles]["aptable"]) do --alle apDaten mit min einer 0 ausfüllen eintragen
		sind=searchSpalte(overview[macs],v.mac)
		overview[11+(nr-1)*3]=replSpalte(overview[11+(nr-1)*3],"0",sind)
		overview[12+(nr-1)*3]=replSpalte(overview[12+(nr-1)*3],"0",sind)
	end
	for apNr,apTbl in pairs(tmpApTable) do --ap daten ergänzen
		sind=searchSpalte(overview[macs],apTbl.mac)
		if apTbl and apTbl.active==1 then
			
			if nr==1 then
				beacons=tonumber(apTbl.beacons)
			else
				print(readSpalte(overview[9+(nr-1)*3],sind))
				print(beacons)
				beacons=tonumber(apTbl.beacons)-tonumber(readSpalte(overview[9+(nr-1)*3],sind))
			end
			overview[12+(nr-1)*3]=replSpalte(overview[12+(nr-1)*3],apTbl.beacons,sind)
		else
			overview[12+(nr-1)*3]=replSpalte(overview[12+(nr-1)*3],readSpalte(overview[9+(nr-1)*3],sind),sind)
			beacons="0"
		end
		
		overview[11+(nr-1)*3]=replSpalte(overview[11+(nr-1)*3],beacons,sind)
	end

	
	
	--clients eifügen		
	for i,v in ipairs(allFiles[#allFiles]["clitable"]) do --alle cli packet-Daten mit min einer 0 ausfüllen eintragen
		sind=searchSpalte(overview[macs],v.mac)
		overview[11+(nr-1)*3]=replSpalte(overview[11+(nr-1)*3],"0",sind)
		overview[12+(nr-1)*3]=replSpalte(overview[12+(nr-1)*3],"0",sind)
		overview[13+(nr-1)*3]=replSpalte(overview[13+(nr-1)*3],"-1",sind)
	end
	for cliNr,cliTbl in pairs(tmpCliTable) do --ap daten ergänzen
		sind=searchSpalte(overview[macs],cliTbl.mac)
		
		if cliTbl and cliTbl.active==1 then
			if nr==1 then
				packets=tonumber(cliTbl.packets)
			else
				packets=tonumber(cliTbl.packets)-tonumber(readSpalte(overview[9+(nr-1)*3],sind))
			end
			overview[12+(nr-1)*3]=replSpalte(overview[12+(nr-1)*3],cliTbl.packets,sind)
			if cliTbl.connected=="(notassociated)" then 
				connected= "0"
			else 
				connected= cliTbl.connected
			end
			overview[13+(nr-1)*3]=replSpalte(overview[13+(nr-1)*3],connected,sind)
		else
			packets="0"
			overview[12+(nr-1)*3]=replSpalte(overview[12+(nr-1)*3],readSpalte(overview[9+(nr-1)*3],sind),sind)
		end
		
		overview[11+(nr-1)*3]=replSpalte(overview[11+(nr-1)*3],packets,sind)
		
		
	end
	
	
end



-- create Overview.csv ------------------------------------------------------------------

print("creating Overview.csv")
sleep(1)
io.output(cD.."Overview.csv","w")

for i=1,(#allFiles*2+12) do
	if overview[i]==nil then overview[i]="," end
end
for i,v in pairs(overview) do
	print("writing",i)
	io.write(v.."\n")
end
io.close()
print("","fin")
sleep(10)




