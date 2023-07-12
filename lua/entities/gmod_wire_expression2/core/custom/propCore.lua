/******************************************************************************\
Prop Core by MrFaul started by ZeikJT update by [G-moder]FertNoN
\******************************************************************************/

PropCore = {}
local sbox_E2_maxProps = CreateConVar( "sbox_E2_maxProps", "-1", FCVAR_ARCHIVE )
local sbox_E2_maxPropsPerSecond = CreateConVar( "sbox_E2_maxPropsPerSecond", "12", FCVAR_ARCHIVE )
local sbox_E2_PropCore = CreateConVar( "sbox_E2_PropCore", "2", FCVAR_ARCHIVE )

local E2totalspawnedprops = 0
local E2tempSpawnedProps = 0

local abs = math.abs 
local function IsValidPos(pos)
	if (pos[1]~=pos[1]) or (pos[2]~=pos[2]) or (pos[3]~=pos[3]) then return false end
	if abs(pos[1]) > 50000 or abs(pos[2]) > 50000 or abs(pos[3]) > 50000 then return false end
	return true
end

function PropCore.ValidSpawn()
	if E2tempSpawnedProps >= sbox_E2_maxPropsPerSecond:GetInt() then return false end
	if sbox_E2_maxProps:GetInt() < 0 then
		return true
	elseif E2totalspawnedprops>=sbox_E2_maxProps:GetInt() then
		return false
	end
	return true
end

function PropCore.ValidAction(self, entity, cmd)
	if(cmd=="spawn" or cmd=="Tdelete") then return true end
	if !IsValid(entity)  then return false end
	if(!validPhysics(entity)) then return false end
	if !isOwner(self, entity)  then return false end
	if entity:IsPlayer() then return false end
	local ply = self.player
	return sbox_E2_PropCore:GetInt()==2 or (sbox_E2_PropCore:GetInt()==1 and ply:IsAdmin())
end

local function MakePropNoEffect(...)
	local backup = DoPropSpawnedEffect
	DoPropSpawnedEffect = function() end
	local ret = MakeProp(...)
	DoPropSpawnedEffect = backup
	return ret
end

function PropCore.CreateProp(self,model,pos,angles,freeze)
	if(!util.IsValidModel(model) || !util.IsValidProp(model) || not PropCore.ValidSpawn() )then
		return nil
	end
	
	if self.player:GetCount( "props" ) >= (GetConVarNumber("sbox_maxprops") > 0 and GetConVarNumber("sbox_maxprops") or self.player:GetCount( "props" )+1) then return nil end
	if !IsValidPos(pos) then return nil end
	
	local prop
	if self.data.propSpawnEffect then
		prop = MakeProp( self.player, pos, angles, model, {}, {} )
	else
		prop = MakePropNoEffect( self.player, pos, angles, model, {}, {} )
	end
	if not prop then return end
	prop:Activate()
	self.player:AddCleanup( "props", prop )
	undo.Create("e2_spawned_prop")
		undo.AddEntity( prop )
		undo.SetPlayer( self.player )
	undo.Finish()
	local phys = prop:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
		if(freeze>0)then phys:EnableMotion( false ) end
	end
	if ( prop.OnDieFunctions.GetCountUpdate == nil ) then prop.OnDieFunctions.GetCountUpdate = {} end
	prop.OnDieFunctions.GetCountUpdate.Function2 = prop.OnDieFunctions.GetCountUpdate.Function
	prop.OnDieFunctions.GetCountUpdate.Function =  function(self,player,class)
		if CLIENT then return end
		E2totalspawnedprops=E2totalspawnedprops-1
		self.OnDieFunctions.GetCountUpdate.Function2(self,player,class)
	end
	E2totalspawnedprops = E2totalspawnedprops+1
	E2tempSpawnedProps = E2tempSpawnedProps+1
	if E2tempSpawnedProps==1 then
		timer.Simple( 1, function()
			E2tempSpawnedProps=0
		end)
	end
	
	return prop
end

function PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
	if(notsolid!=nil) then this:SetNotSolid(notsolid ~= 0) end
	local phys = this:GetPhysicsObject()
	if(pos!=nil) then E2Lib.setPos( phys, Vector(pos[1],pos[2],pos[3]) ) end
	if(rot!=nil) then E2Lib.setAng( phys,  Angle(rot[1],rot[2],rot[3]) ) end
	if(freeze!=nil) then phys:EnableMotion(freeze == 0) end
	if(gravity!=nil) then phys:EnableGravity(gravity~=0) end
	phys:Wake()
	if(!phys:IsMoveable())then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end
end

--------------------------------------------------------------------------------
__e2setcost(150)
e2function entity propSpawn(string model, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, vector pos, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(entity template, vector pos, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),frozen)
end

e2function entity propSpawn(string model, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),self.entity:GetPos()+self.entity:GetUp()*25,Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(string model, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function entity propSpawn(entity template, vector pos, angle rot, number frozen)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	if not IsValid(template) then return nil end
	return PropCore.CreateProp(self,template:GetModel(),Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),frozen)
end

e2function number propCanSpawn()
	if self.player:GetCount( "props" ) >= (GetConVarNumber("sbox_maxprops") > 0 and GetConVarNumber("sbox_maxprops") or self.player:GetCount( "props" )+1) then return 0 end
	if E2tempSpawnedProps >= sbox_E2_maxPropsPerSecond:GetInt() then return 0 end
	if E2totalspawnedprops >= (sbox_E2_maxProps:GetInt() > 0 and sbox_E2_maxProps:GetInt() or E2totalspawnedprops+1) then return 0 end
	return 1
end
--------------------------------------------------------------------------------
__e2setcost(50)
e2function void entity:propDelete()
	if not PropCore.ValidAction(self, this, "delete") then return end
	this:Remove()
end

e2function void entity:propBreak()
	if not PropCore.ValidAction(self, this, "break") then return end
	this:Fire("break",1,0)
end

local function removeAllIn( self, tbl )
	local count = 0
	for k,v in pairs( tbl ) do
		if (IsValid(v) and isOwner(self,v) and !v:IsPlayer()) then
			count = count + 1
			v:Remove()
		end
	end
	return count
end

e2function number table:propDelete()
	if not PropCore.ValidAction(self, nil, "Tdelete") then return end

	local count = removeAllIn( self, this.s )
	count = count + removeAllIn( self, this.n )

	self.prf = self.prf + count

	return count
end

e2function number array:propDelete()
	if not PropCore.ValidAction(self, nil, "Tdelete") then return end

	local count = removeAllIn( self, this )

	self.prf = self.prf + count

	return count
end

--------------------------------------------------------------------------------
e2function void entity:propManipulate(vector pos, angle rot, number freeze, number gravity, number notsolid)
	if not PropCore.ValidAction(self, this, "manipulate") then return end
	PropCore.PhysManipulate(this, pos, rot, freeze, gravity, notsolid)
end

e2function void entity:propFreeze(number freeze)
	if not PropCore.ValidAction(self, this, "freeze") then return end
	PropCore.PhysManipulate(this, nil, nil, freeze, nil, nil)
end

e2function void entity:propNotSolid(number notsolid)
	if not PropCore.ValidAction(self, this, "solid") then return end
	PropCore.PhysManipulate(this, nil, nil, nil, nil, notsolid)
end

e2function void entity:propGravity(number gravity)
	if not PropCore.ValidAction(self, this, "gravity") then return end
	PropCore.PhysManipulate(this, nil, nil, nil, gravity, nil)
end

e2function void entity:propSleep()
	if not PropCore.ValidAction(self, this, "sleep") then return end
	this:GetPhysicsObject():Sleep()
end

e2function void entity:propMove(status)
	if not PropCore.ValidAction(self, this, "move") then return end
	this:SetMoveType( tobool(status) and 6 or 0 )
end

e2function void entity:propBuoyancy(number buoyancy)
	if not PropCore.ValidAction(self, this, "buoyancy") then return end
	this:GetPhysicsObject():SetBuoyancyRatio( math.Clamp(buoyancy/100,0,1) )
end

e2function void entity:propDamping(number linear,number angular)
	if not PropCore.ValidAction(self, this, "damping") then return end
	this:GetPhysicsObject():SetDamping( math.Clamp(linear,-10,10000000) , math.Clamp(angular,-10,10000000) )
end

--------------------------------------------------------------------------------



--------------------------------------------------------------------------------

local blacklistedClasses = {
	['crossbow_bolt'] = true,
	['prop_combine_ball'] = true,
	['item_ammo_smg1_grenade'] = true,
	['npc_grenade_frag'] = true,
	['npc_satchel'] = true,
	['npc_tripmine'] = true,
}

e2function void entity:setPos(vector pos)
	if !IsValid(this)  then return end
	if blacklistedClasses[ this:GetClass() ] then error("[E2p]: недопустимый класс энтити entity:setPos()!") return end
	if !isOwner(self, this) then return end
	if this:IsPlayer() then
		if !this:InBuildMode() and !self.player:IsAdmin() then 
			error("[E2p]: нельзя использовать entity:setPos() в PVP!") 
			return 
		end
	end
	if !IsValidPos(pos) then return end
	if validPhysics(this) then 
		local phys = this:GetPhysicsObject()
		phys:SetPos(Vector(pos[1],pos[2],pos[3]))
		phys:Wake()
	else
		this:SetPos(Vector(pos[1],pos[2],pos[3]))
	end
end

e2function void entity:setAng(angle rot)
	if !IsValid(this)  then return end
	if !isOwner(self, this) then return end
	if !IsValidPos(rot) then return end
	if validPhysics(this) then 
		local phys = this:GetPhysicsObject()
		phys:SetAngles(Angle(rot[1],rot[2],rot[3]))
		phys:Wake()
	else
		this:SetAngles(Angle(rot[1],rot[2],rot[3]))
	end
end

e2function void entity:setVel(vector vel)
	if not self.player:GetNWBool("E2PowerAccess") then error( "[E2p]: у тебя нет доступа к setVel()!" ) return end
	if !IsValid(this)  then return end
	if !isOwner(self,this)  then return end
	if validPhysics(this) then 
	this:GetPhysicsObject():SetVelocity(Vector(vel[1],vel[2],vel[3])) 
	else
	this:SetVelocity(Vector(vel[1],vel[2],vel[3]))
	end
end

e2function void entity:setPersistent(number status)
	if !IsValid(this)  then return end
	if !isOwner(self,this)  then return end
	this:SetPersistent(tobool(status))
end

local isValidBone = E2Lib.isValidBone
e2function void bone:setPos(vector pos)
	local ent=isValidBone(this)
	if !ent then return end
	if !isOwner(self, this) then return end
	if !IsValidPos(pos) then return end
	this:SetPos(Vector(pos[1],pos[2],pos[3]))
	this:Wake()
end

e2function void bone:boneGravity(status)
	local ent=isValidBone(this)
	if !ent then return end
	if !isOwner(self, this) then return end
	local status = status > 0
	this:EnableGravity(status) 
end

e2function void bone:setVel(vector vel)
	if not self.player:GetNWBool("E2PowerAccess") then error( "[E2p]: у тебя нет доступа к setVel()!" ) return end
	local ent=isValidBone(this)
	if !ent then return end
	if !isOwner(self, this) then return end
	this:SetVelocity(Vector(vel[1],vel[2],vel[3])) 
end

e2function void bone:boneFreeze(number freeze)
	local ent=isValidBone(this)
	if !ent then return end
	if !isOwner(self, this) then return end
	this:EnableMotion(freeze == 0)
end

local function parent_check( child, parent, self )
	while IsValid( parent ) do
		if (child == parent) then
			return false
		end
		parent = parent:GetParent()
		self.prf = self.prf + 10
	end
	return true
end

e2function void entity:setParent(entity ent)
	if !IsValid(this) then return end
	if this:IsPlayer() then return end
	if !isOwner(self,this)  then return end
	if !IsValid(ent) then return end
	if !isOwner(self,ent)  then return end
	if !parent_check( this, ent, self ) then return end
	this:SetParent( ent )
end

e2function void entity:unParent()
	if !IsValid(this) then return end
	if !isOwner(self,this)  then return end
	this:SetParent()
end

e2function void entity:parentTo(entity target)
	if not PropCore.ValidAction(self, this, "parent") then return end
	if not IsValid(target) then return nil end
	if(!isOwner(self, target)) then return end
	if this == target then return end
	if !parent_check( this, target, self ) then return end
	this:SetParent(target)
end

e2function void entity:deparent()
	if not PropCore.ValidAction(self, this, "deparent") then return end
	this:SetParent( nil )
end

e2function void propSpawnEffect(number on)
	self.data.propSpawnEffect = on ~= 0
end

registerCallback("construct", function(self)
	self.data.propSpawnEffect = true
end)

__e2setcost(10)
e2function number isValidModel(string model)
	if util.IsValidModel(model) then return 1 end
	return 0
end

e2function number isValidProp(string model)
	if util.IsValidProp(model) then return 1 end
	return 0
end

e2function number entity:isPersistent()
	if !IsValid(this) then return 0 end
	return this:GetPersistent() and 1 or 0
end

e2function vector2 entity:getDamping()
	if !IsValid(this) then return {0,0} end
	local phys = this:GetPhysicsObject()
	if IsValid(phys) then return {phys:GetSpeedDamping(),phys:GetRotDamping()} end
	return {0,0}
end

e2function number entity:isAsleep()
	if !IsValid(this) then return 0 end
	local phys = this:GetPhysicsObject()
	if IsValid(phys) then return phys:IsAsleep() and 1 or 0 end
	return 0
end

e2function number entity:gravity()
	if !IsValid(this) then return 0 end
	return this:GetGravity() and 1 or 0
end











