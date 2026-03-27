--!strict
--!optimize 2
--!native

--[[
    ANEX: Customizable state management for the Allure Ecosystem
    By r-iva9
    1.0.0
    Open source (MIT)
    https://github.com/r-iva9/Anex

    ALLURE FULLSTACK ECOSYSTEM
    By r-iva9
	https://github.com/r-iva9/Allure
]]

------------
-- TYPES

--[=[
	luau type blanks
]=]

type table<K = any, V = any> = { [K]: V }
type fn = <A..., R...>(A...) -> R...
type ffor<R...> = <A...>(A...) -> R...
type with<A...> = <R...>(A...) -> R...
type withself<T, A...> = <R...>(self: T, A...) -> R...

type Hook<T=any> = {
	--[=[
		Call each connected function with the arguments `(self, value)`
	]=]
	Fire: (self: Hook<T>, value: T) -> Hook<T>,
	Connections: table<any, withself<Hook<T>, T>>,

	--[=[
		Shortcut for `Hook.Connections[key] = value`

		Supports variations:
		```lua
		Hook:Connect("key")(fn) --returns Hook

		Hook:Connect("key", fn) --returns a function

		Hook:Connect("key", fn)() --returns Hook

		Hook:Connect(fn) --returns a function
		```
		Where `fn` is a callback
	]=]
	Connect: (self: Hook<T>, name: any) -> (withself<Hook<T>, T>?) -> Hook<T>
}

export type State<T=any> = setmetatable<
{
	--[=[
		Call each connected function with the arguments `(self, value)`
	]=]
	Fire: (self: Hook<T>, value: T) -> Hook<T>,
	Connections: table<any, withself<Hook<T>, T>>,
	
	--[=[
		Shortcut for `Hook.Connections[key] = value`

		Supports variations:
		```lua
		Hook:Connect("key")(fn) --returns Hook

		Hook:Connect("key", fn) --returns a function

		Hook:Connect("key", fn)() --returns Hook

		Hook:Connect(fn) --returns a function
		```
		Where `fn` is a callback
	]=]
	Connect: (self: Hook<T>, name: any) -> (withself<Hook<T>, T>?) -> Hook<T>,

	Val: T,
	Get: ffor<T>,
	Set: (self: State<T>, T) -> T,

	--[=[
		Replaces the inner setter, the function that changes the value, with the specified `fn`
		<br>Does not overwrite calling `State()` as the getter

		Default setter:
		```luau
		function(self, value)
			self.Val = value
			self:Fire(self.Val)
			return self.Val
		end
		```
	]=]
	Setter: (self: State<T>, fn: (self: State<T>, T) -> T) -> State<T>,

	--[=[
		Replaces the inner getter, the function that returns the value, with the specified `fn`

		Default getter:
		```luau
		function(self)
			return self.Val
		end
		```
	]=]
	Getter: (self: State<T>, fn: ffor<T>) -> State<T>,

	--[=[
		Calls `fn` before the default deleter function of the State

		Default deleter:
		```luau
		function(...) end
		```
	]=]
	Deleter: (self: State<T>, fn: fn) -> State<T>,

	--[=[
		Destroys the state, calls the deleter and cleans memory
	]=]
	Destroy: fn,
}, {
	__isstateflag: true,
	__call: (self: State<T>, ...Stateable<T>?) -> T,

	__add: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__sub: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__mul: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__mod: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__pow: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__div: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__idiv: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,
	__concat: (self: Stateable<T>, other: Stateable<T>) -> Stateable<T>,

	__unm: (self: State) -> any,

	--relational metamethods:
	__eq: (self: State, other: State) -> boolean,
	__le: (self: State, other: State) -> boolean,
	__lt: (self: State, other: State) -> boolean,

	--tostring:
	__tostring: (self: State<T>) -> string,
}>

type Stateable<T=any> = any | State<T>

type HookConstructor = <S, T>(container: S, start: T) -> Hook<T>
type StateConstructor = <S, T, A>(container: S, value: T, overhead: A?) -> State<T>

------------
-- UTILITY

local Anex = nil :: never

--- Returns a typesafe reference to `t`
local function ref<T>(t: T): any
	return t :: any
end

--- Returns `true` is the value is a State and `false` if not
local function isstate(value: any): boolean
	return typeof(value) == "table" and value.Val ~= nil and value.Connect and value.Fire and value.Setter
end

--- Returns a function that returns a state that displays an operation on the 2 specified states
local function withstates(val: (Stateable, Stateable) -> any): 
	(self: Stateable, other: Stateable) -> Stateable
	return function(self: Stateable, other: Stateable): Stateable
		local new = Anex:State(val(self, other))

		local f = function(_, __)
			new(val(self, other))
		end
		if isstate(self) then self:Connect(new)(f) end
		if isstate(other) then other:Connect(new)(f) end
		return new
	end
end

--- Returns a function that returns a state that displays an operation on the specified state
local function withstate<T>(val: (State<T>) -> T): 
	(self: State<T>) -> State<T>
	return function(self: State<T>): State<T>
		local new = Anex:State(val(self))

		self:Connect(new)(function(_, __)
			new(val(self))
		end)
		return new
	end
end

------------
-- ANEX

Anex = {
	Name = "Anex",
	Version = "1.0.0",
	Author = "r-iva9",

	--- ALLURE
	Tags = {
		Priority = 0,
		Instance = script,
	},
	Dependencies = {},
	Instance = script,
}

--[=[
	Creates a new Hook object within the `container` table if it's not Anex

	Hooks can `:Fire` all connected functions with one value
]=]
Anex.Hook = function<S, T>(container: S, start: T): Hook<T>
	local self = {
		Fire = function(self: Hook<T>, value: T): Hook<T>
			for _, conn in self.Connections do
				conn(self, value)
			end
			return self
		end,
		Connections = {},
		Connect = function(self: Hook<T>, key: any, ...: withself<Hook<T>, T>?)
			if select('#', ...) == 0 then
				if key then self.Connections[key] = key end
				return function(value: withself<Hook<T>, T>?)
					self.Connections[key or value] = value
					return self
				end
			else
				local val = ({...})[1]
				self.Connections[key or val] = val
				return function(...) return self end
			end
		end
	}
	if container ~= Anex then
		table.insert(container, self)
	end
	return self
end

local stateMt = {
	__isstateflag = true,
	__call = function<T>(self: State<T>, ...: Stateable?): T
		local i = select('#', ...)
	
		return if i==0 then self:Get() else self:Set(... :: any)
	end,

	__add = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) + (isstate(other) and other() or other)
	end),
	__sub = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) - (isstate(other) and other() or other)
	end),
	__mul = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) * (isstate(other) and other() or other)
	end),
	__mod = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) % (isstate(other) and other() or other)
	end),
	__pow = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) ^ (isstate(other) and other() or other)
	end),
	__div = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) / (isstate(other) and other() or other)
	end),
	__idiv = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) // (isstate(other) and other() or other)
	end),
	__concat = withstates(function(self: Stateable, other: Stateable): Stateable
		return (isstate(self) and self() or self) .. (isstate(other) and other() or other)
	end),

	__unm = withstate(function(self: any): any
		return -(self())
	end),

	__eq = function(self: Stateable, other: Stateable): any
		return self() == other()
	end,
	__le = function(self: Stateable, other: Stateable): any
		return self() <= other()
	end,
	__lt = function(self: Stateable, other: Stateable): any
		return self() < other()
	end,

	__tostring = function(self: State): string
		return tostring(self())
	end,
}

--[=[
	Creates a new mutable State within the `container` table if it's not Anex

	States are extensions of Hooks encapsulating a value, setter and getter.
]=]
Anex.State = function<S, T, A>(container: S, value: T, overhead: A?): State<T>
	local self = Anex:Hook(value) :: table
	self.Val = value

	local deleter = function(...) end
	local setter = function(_, value) 
		self.Val = value
		self:Fire(self.Val)
		return self.Val
	end

	self.Get = function<A...>(_, ...: A...): T
		return self.Val
	end
	self.Set = function(self: State<T>, value: any): T
		if isstate(value) then
			--is a state
			if value==self then self:Fire(self.Val) end

			value:Connect(self)(function(_, a1) 
				self:Set(a1)
			end)
			value = value()

		elseif typeof(value)=="table" and value.Fire and value.Connections and value.Connect then
			--is a hook
			ref(value):Connect(self)(function(_, a1) 
				self:Set(a1)
			end)
			return self.Val

		end

		return setter(self, value)
	end
	self.Destroy = function<A..., R...>(...: A...): R...
		deleter(...)

		table.clear(getmetatable(self) :: any)
		setmetatable(self :: never, nil)

		table.clear(self)
		self = nil :: any
	end

	self.Setter = function(self: State<T>, fn: (self: State<T>, T) -> T): State<T>
		setter = fn
		return self
	end

	self.Getter = function(self: State<T>, fn: ffor<T>): State<T>
		self.Get = fn
		return self
	end
	self.Deleter = function(self: State<T>, fn: fn): State<T>
		deleter = fn
		return self
	end

	if container ~= Anex and typeof(container) == "table" then
		table.insert(container, self)
	end

	return setmetatable(self, stateMt)
end :: StateConstructor

return Anex