<p align="center">
  <h1 align="center"><i><ins>Anex</ins></i></h1>
</p>

<p align="center">
  <b><i>Customizable state management<br>for Luau and the <a href=https://github.com/r-iva9/Allure>Allure Ecosystem</a></i></b>
</p>

## 📦 Installation
Install via wally:
```
Anex = "r-iva9/anex@1.0.0"
```

## 🍀 Benefits

- ***Comfortable and syntax minimal***
  > Set states via `state(val)`, get states via `state()`, connect states via `stateA(stateB)`<br>
  > Create new states from `stateA + stateB`, `stateA .. stateB` and more!

- ***Customizable***
  > Customize how your states change via `state:Setter()`<br>
  > Customize how your states give you their value via `state:Getter()`.

- ***Suited for the Allure Ecosystem***
  > Very easy to use with Allure and other modules of the ecosystem.

# ⚒️ Basic usage

Anex introduces basic Hooks and States.

## Hooks

Create a new Hook:

```luau
local myHook = Anex:Hook()
```
Connect a function to the hook via any of the 3 methods:
```luau
myHook:Connect(callback)
myHook:Connect(name, callback)
myHook:Connect(name)(callback)

--Disconnect:
myHook:Connect(name)(nil)
```
Fire the connections:
```luau
myHook:Fire(100)
```

Additionally, you can create a hook ***into a container***:

```luau
local container = {}

Anex.Hook(container)
```

## States

Anex implements states with a focus on customization and comfort, realizing it syntax-minimally.

Create a new State:

```luau
local myState = Anex:State(100)

-- Just like with hooks, create a state into a container:
local myState = Anex.State(container, 100)
```
Set the state:
```luau
local a = myState(200)
```
It returns the new value.

Get the state:
```luau
local a = myState()
```

> [!NOTE]
> Similarly to *Vide*, this implementation is syntax minimal, so calling
> ```luau
> myState(nil)
> ```
> will set the state to `nil`, while
> ```luau
> myState()
> ```
> will simply return the actual state value.

States are hooks underneath, so you can Connect and Fire states just the same:

```luau
myState:Connect(callback)
myState:Fire()
```
In this sense, calling `myState:Fire()` is identical to `myState(myState())`

### Shortcuts

Adding two states together (`stateA + stateB`) will, instead of yielding an error, generate a new state, which computes the sum of two states:
```luau
local stateA = Anex:State(10)
local stateB = Anex:State(15)

local stateC = stateA + stateB

print(stateC()) --25
```
This state updates whenever any of the states update:
```luau
stateA(40)

print(stateC()) --55
```
Connecting a function to `stateC` will call the function whenever `stateA` or `stateB` change.

The same you can get from:
- `A - B`, `A * B`, `A ^ B`,
- `A / B`, `A // B`, `A .. B`,
- `-A`
  
And you can get the actual results from:
- `A == B`, `A <= B`,
- `A < B` and `tostring(A)`

Additionally, whenever you "set" a state to an another state
```luau
stateA(stateB)
```
instead of setting the value to an entire state, Anex connects `stateA` to `stateB`, so that whenever `stateB` updates, `stateA` will update to the value of `stateB`.

### Setter and getter

Anex allows you to customize your states and set their *setter* and *getter*.

The principle is self explanatory: the setter is called to set your state's value:

```luau
local state = Anex:State(100)

-- A setter that sets double of the specified value
state:Setter(function(self, value)
  self.Val = value * 2
  self:Fire(value * 2)
  return self.Val * 2
end)

state(200)

print(state()) --400
print(state.Val) --400
```

The getter allows you to get a different value when you ask for it:
```luau
local state = Anex:State(100)

state:Getter(function(self)
  return self.Val * 2
end)

print(state()) --200
print(state.Val) --100
```

## License

Anex is shared freely with the MIT license, it's a part of the Allure Ecosystem.
<br>*For more information refer to https://github.com/r-iva9/Allure*
<br>Give me a shoutout if you want!
