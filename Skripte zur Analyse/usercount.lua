--  *************************************************************************
--  * Dies ist ein Skript zur Auswertung, das für die Maturaarbeit 2014/15  *
--  *                  von Simon Studer entwickelt wurde.                   *
--  *   Es ist zum Zeitpunkt der Abgabe (5.1.2015) die finale Version zum   *
--  *   Programm und wird in Zukunft verbessert oder verändert im Ordner    *
--  *                             /postRelease/                             *
--  *                             aktualisiert.                             *
--  *************************************************************************

-- Dieses Skript wird auf einem Computer mit Lua for Windows oder ähnlichem ausgeführt und muss sich im gleichen Ordner wie die Datei Overview.csv (oder umbenannt) befinden.
-- Es wird im demselben Ordner eine Auswertungsdatei Overview.csv erstellt

-- Parameter:  usercount.lua filename searchType
-- filename ist die Auswertungsdatei (Overview.csv)
-- searchType ist entweder "ap" oder "client"


function sleep(n)
local t0 = os.clock()
while os.clock() - t0 <= n do end
end


cD=arg[0]
cD=string.reverse(cD)
cD=string.sub(cD,string.find(cD,"\\")+1)..""
cD=string.reverse(cD)
cD=cD.."/"
cD=string.gsub(cD,"\\","/")
filename=arg[1]
search=arg[2]
content={}
tmpContent={}
io.input(cD.."/"..filename)
print(cD,filename,search)
for line in io.lines() do
	table.insert(tmpContent,line)
end
for i,v in pairs(tmpContent) do
	print(i)
	content[i]={}
	line=v
	if #line<1 then print(#line,line) sleep(2) end
	while string.find(line,",") do
		table.insert(content[i],string.sub(line,1,string.find(line,",")-1).."")
		line=string.sub(line,string.find(line,",")+1)..""
	end
	line=line.." "
	table.insert(content[i],line)
end

if search=="ap" then
	searchStart=3
	for i,v in pairs(content[3]) do
		if string.find(v,"clients") then searchStop=i-2 break end
	end
elseif search=="client" then
	for i,v in pairs(content[3]) do
		if string.find(v,"clients") then searchStart=i+1 end
		if string.find(v,"stop") then searchStop=i-3 end
	end
end
print(search,searchStart,searchStop)

users={}
times={}
counter=1
for zeilenNr,zeilenInhalt in pairs(content) do
print(#content)
print(zeilenNr)
print(type(zeilenNr))
	if  tonumber(zeilenNr)>10 and (tonumber(zeilenNr)-11)%3==tonumber(0) then
		activeCounter=0
		for i=searchStart,searchStop do
		print(content[zeilenNr][i])
		print(type(content[zeilenNr][i]))
		print(#content[zeilenNr][i])
		print(zeilenNr,i)
			if content[zeilenNr][i]~=nil then
			print("entered")
				if tonumber(content[zeilenNr][i])>0 then
					print("beacons",content[zeilenNr][i])
					activeCounter=activeCounter+1
				end
			end
		end
		users[counter]=activeCounter
		times[counter]=content[zeilenNr][1]
		counter=counter+1
	end
end

io.output(cD.."usercount-"..search..".csv","w")

for i,v in pairs(users) do
	if i>1 then
		io.write(times[i]..","..v.."\n")
	end
end
io.close()

























