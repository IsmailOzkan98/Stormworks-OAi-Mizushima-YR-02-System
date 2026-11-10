local I={M=1,TRH=2,TP=3,TR=4,RR=5,A=6,AT=7,P=8,IN=9,D=10,AD=11,VS=12,KX=13,KY=14,SX=15,SY=16,C=17,ST=18,CO=19,DZ=20,SM=21,VST=22,TRV=23,START=1}
local O={RL=1,RR=2,EL=3,ER=4,SP=5,AY=6,AD=7,MX=8,MY=9,TX=10,TY=11,MB=1,BN=5,BE=6,BS=7,BW=8,AB=9,SS=32}

local C={TR=60,AG=.35,MC=105,MD=125,MIN=-.45,MAX=.45,IL=10,CR=.005,AST=2,RST=.2,DBP=.2}
local T={EN=true,PORT=8080,INT=6,t=0}
local M={RPS=1,ALT=15,ROLL=.005,PITCH=.08,PST=.01}
local B={EN=true,Z=25/360,MIN=.001}

local S={i=0,pVS=0,aCS=0,aY=0}

local function cl(v,a,b)return math.max(a,math.min(b,v))end
local function ad(a,b)return math.abs((a-b+.5)%1-.5)end

local function ri()
 return {
 m=input.getNumber(I.M),rH=input.getNumber(I.TRH),rV=input.getNumber(I.TRV),
 pT=input.getNumber(I.TP),tR=input.getNumber(I.TR),rR=input.getNumber(I.RR),
 a=input.getNumber(I.A),aT=input.getNumber(I.AT),
 P=input.getNumber(I.P),I=input.getNumber(I.IN),D=input.getNumber(I.D),
 aD=input.getNumber(I.AD),vS=input.getNumber(I.VS),vST=input.getNumber(I.VST),
 kX=input.getNumber(I.KX),kY=input.getNumber(I.KY),
 sX=input.getNumber(I.SX),sY=input.getNumber(I.SY),
 c=input.getNumber(I.C),sP=input.getNumber(I.ST),
 cD=input.getNumber(I.CO),dZ=input.getNumber(I.DZ),
 yS=input.getNumber(I.SM)/1000,
 start=input.getBool(I.START)
 }
end

local function roll(d,en)
 local v=en and d.rH*d.m or 0
 return {rL=v,rR=-v}
end

local function pitch(d)
 return math.abs(d.pT)<=M.PST
end

local function bot(d,en)
 local r={u=false,d=false,t=false,c=false}
 if not en or not B.EN then return r end
 local mag=math.sqrt(d.rH*d.rH+d.rV*d.rV)
 if mag<B.MIN then return r end
 local a=math.atan(d.rH,d.rV)
 local bA=(a+math.pi)%(math.pi*2)/(math.pi*2)
 local z=B.Z/2
 r.u=ad(bA,.25)<=z
 r.d=ad(bA,0)<=z
 r.t=ad(bA,.75)<=z
 r.c=ad(bA,.50)<=z
 return r
end

local function ap(d,en)
 local x=d.kX-d.sX
 local y=d.kY-d.sY
 local dist=math.sqrt(x*x+y*y)
 local ang=math.atan(x,y)
 local pi2=math.pi*2
 local tH=(d.c+ang/pi2)%1
 local yE=((d.c+ang/pi2)%1+1.5)%1-.5
 local yT=yE*d.sP
 yT=cl(yT,-1,1)
 if math.abs(yE)<d.dZ then yT=0 end
 if dist<d.cD then yT=0 end
 if not en then
  S.aY=0
 else
  local sm=math.max(0,d.yS)
  local df=yT-S.aY
  S.aY=S.aY+cl(df,-sm,sm)
 end
 return {y=S.aY,dist=dist,tH=tH,en=en}
end

local function alt(d,en)
 local dt=1/C.TR
 local aE=d.aT-d.a
 local dVS=0
 local vE=0
 local aC=0
 if en then
  dVS=cl(aE*C.AG,-C.MD,C.MC)
  vE=dVS-d.vS
  local pp=d.P*vE
  local vA=(d.vS-S.pVS)/dt
  local der=-d.D*vA
  local cI=cl(S.i+vE*dt,-C.IL,C.IL)
  local out=pp+der
  local uns=out+d.I*cI
  local sat=cl(uns,C.MIN,C.MAX)
  if uns==sat or (uns>C.MAX and vE<0) or (uns<C.MIN and vE>0) then
   S.i=cI
  end
  aC=cl(out+d.I*S.i,C.MIN,C.MAX)
  S.pVS=d.vS
 else
  S.i=0
  S.pVS=d.vS
  S.aCS=0
 end
 local df=aC-S.aCS
 S.aCS=S.aCS+cl(df,-C.CR,C.CR)
 return {aE=aE,dVS=dVS,vE=vE,aC=aC,eO=S.aCS}
end

local Q={
 st=0,t=0,aST=0,rST=0,
 run=false,done=false,pS=false,
 vSE=false,dBU=false,dBP=false,dBPT=0,
 dBS={n=false,e=false,s=false,w=false},
 cmd={rS=false,aH=false,aP=false,mB=false,sp=0,aB=false,bB=false}
}

local F={
 {name="ENGINE_CHECK",set={sp=1},wait={type="rps_min"}},
 {name="ROLL_STABILIZER",set={rS=true},wait={type="rps_min"}},
 {name="MAIN_BOOSTER",set={mB=true},wait={type="vertical_speed_max"}},
 {name="DIRECTIONAL_BOOSTER",wait={type="pitch"}},
 {name="BOTTOM_BOOSTER_SYSTEM",set={bB=true}},
 {name="ACCELERATION_BOOSTERS",set={aB=true,sp=0},wait={type="alt_hold_delay"}},
 {name="ROLL_STABILITY_CHECK",set={bB=false},wait={type="roll"}},
 {name="ALTITUDE_HOLD",set={aH=true},wait={type="altitude"}},
 {name="AUTOPILOT",set={aP=true},wait={type="autopilot_target"}},
 {name="AUTOPILOT_COMPLETE",set={aP=false},hold=true}
}

local function enter(i)
 local f=F[i]
 if not f then return end
 Q.st=i
 Q.t=0
 Q.aST=0
 Q.rST=0
 if i==1 then
  Q.dBU=false
  Q.dBP=false
  Q.dBPT=0
 end
 if i==4 and not Q.dBU then
  Q.dBU=true
  Q.dBP=true
 end
 if i==3 then Q.vSE=false end
 if f.set then
  for k,v in pairs(f.set) do Q.cmd[k]=v end
 end
end

local function cond(d,w)
 if not w then return true end
 local t=w.type
 if t=="rps_min" then
  return d.rR>=d.tR-M.RPS
 elseif t=="vertical_speed_max" then
  if d.vS>d.vST then Q.vSE=true end
  return Q.vSE and d.vS<=d.vST
 elseif t=="pitch" then
  return math.abs(d.pT)<=M.PITCH
 elseif t=="alt_hold_delay" then
  return Q.t>=math.max(0,d.aD)*C.TR
 elseif t=="altitude" then
  local stable=math.abs(d.aT-d.a)<=M.ALT
  if stable then Q.aST=Q.aST+1 else Q.aST=0 end
  return stable and Q.aST>=C.AST*C.TR
 elseif t=="roll" then
  local stable=math.abs(d.rH)<=M.ROLL
  if stable then Q.rST=Q.rST+1 else Q.rST=0 end
  return Q.rST>=C.RST*C.TR
 elseif t=="autopilot_target" then
  local x=d.kX-d.sX
  local y=d.kY-d.sY
  return math.sqrt(x*x+y*y)<d.cD
 end
 return false
end

local function seq(d)
 local edge=d.start and not Q.pS
 Q.pS=d.start
 if edge and not Q.run and not Q.done then
  Q.run=true
  enter(1)
 end
 if not Q.run then return end
 local f=F[Q.st]
 if not f then Q.run=false return end
 if f.hold then
  Q.done=true
  Q.run=false
  return
 end
 Q.t=Q.t+1
 if cond(d,f.wait) then
  local nx=Q.st+1
  if nx>#F then
   Q.done=true
   Q.run=false
  else
   enter(nx)
  end
 end
end

local function dir(h,en)
 local a=(h+.5)%1
 a=(a+.5)%1-.5
 return {
 n=en and a>=-.125 and a<.125,
 e=en and a>=.125 and a<.375,
 s=en and (a>=.375 or a<-.375),
 w=en and a>=-.375 and a<-.125
 }
end

local function out(f,a,p,b,d)
 output.setNumber(O.RL,f.rL)
 output.setNumber(O.RR,f.rR)
 output.setNumber(O.EL,a.eO)
 output.setNumber(O.ER,a.eO)
 output.setNumber(O.SP,Q.cmd.sp)
 output.setBool(O.MB,Q.cmd.mB)
 output.setBool(O.BN,b.n)
 output.setBool(O.BE,b.e)
 output.setBool(O.BS,b.s)
 output.setBool(O.BW,b.w)
 output.setBool(O.AB,Q.cmd.aB)
 output.setBool(O.SS,d.start)
 output.setNumber(O.AY,p.y)
 output.setNumber(O.AD,p.dist)
 output.setNumber(O.MX,d.sX)
 output.setNumber(O.MY,d.sY)
 output.setNumber(O.TX,d.kX)
 output.setNumber(O.TY,d.kY)
end

local function tel(d,a,p,b)
 if not T.EN then return end
 T.t=T.t+1
 if T.t<T.INT then return end
 T.t=0
 local f=F[Q.st]
 local stage=f and f.name or "STANDBY"
 local status="IDLE"
 if Q.run then status="RUNNING"
 elseif Q.done then status="COMPLETED" end
 local url=string.format(
 "/telemetry?stage=%s&state=%d&status=%s&timer=%d&alt=%.2f&alt_target=%.2f&alt_error=%.2f&vs=%.2f&vs_target=%.2f&vs_error=%.2f&rps=%.2f&rps_target=%.2f&roll=%.4f&pitch=%.4f&ap=%d&ap_distance=%.2f&yaw=%.4f&my_x=%.2f&my_y=%.2f&target_x=%.2f&target_y=%.2f&main=%d&alt_hold=%d&roll_stab=%d&accel=%d&north=%d&east=%d&south=%d&west=%d&spoiler=%.2f",
 stage,Q.st,status,Q.t,
 d.a,d.aT,a.aE,d.vS,a.dVS,a.vE,
 d.rR,d.tR,d.rH,d.pT,
 p.en and 1 or 0,p.dist,p.y,
 d.sX,d.sY,d.kX,d.kY,
 Q.cmd.mB and 1 or 0,
 Q.cmd.aH and 1 or 0,
 Q.cmd.rS and 1 or 0,
 Q.cmd.aB and 1 or 0,
 b.n and 1 or 0,b.e and 1 or 0,
 b.s and 1 or 0,b.w and 1 or 0,
 Q.cmd.sp
 )
 async.httpGet(T.PORT,url)
end

function onTick()
 local d=ri()
 seq(d)
 local p=ap(d,Q.cmd.aP)
 local b=dir(p.tH,false)

 if Q.dBP then
  Q.dBS=dir(p.tH,true)
  Q.dBPT=math.max(1,math.ceil(C.DBP*C.TR))
  Q.dBP=false
 end

 if Q.dBPT>0 then
  b=Q.dBS
  Q.dBPT=Q.dBPT-1
 end

 local f=roll(d,Q.cmd.rS)
 local a=alt(d,Q.cmd.aH)
 local bt=bot(d,Q.cmd.bB)

 local bo={
  n=b.n or bt.c,
  e=b.e or bt.t,
  s=b.s or bt.d,
  w=b.w or bt.u
 }

 out(f,a,p,bo,d)
 tel(d,a,p,bo)
end