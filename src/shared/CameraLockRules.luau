local Rules={}
function Rules.active(state)
	return state.requested==true and state.alive==true and state.focused==true
		and not state.typing and not state.menu and not state.flying and not state.seated
		and not state.platform and not state.scripted
end
return Rules
