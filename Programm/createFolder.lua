#!/usr/bin/lua
workingPath="/mnt/sda1/arduino/programs/analyseWlan/output/"

io.input(io.open(workingPath.."last.txt","r"))
content={}
for line in io.lines() do
  table.insert(content,line)
end
io.close()
if content[1]=="" or content[1]==nil then content[1]=0 end
nr=tonumber(content[1])+1

io.output(io.open(workingPath.."last.txt","w"))
io.write(tostring(nr))
io.close()

io.output(io.stdout)
io.write(tostring(nr))