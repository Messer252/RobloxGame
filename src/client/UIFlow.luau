local Flow = {}
function Flow.metrics(count, width, minWidth, maxColumns, gap, height)
	local columns = math.max(1, math.min(maxColumns, count, math.floor((width + gap) / (minWidth + gap))))
	local rows = math.ceil(count / columns)
	return columns, math.max(1, math.floor((width - gap * (columns - 1)) / columns)), rows * height + math.max(0, rows - 1) * gap
end
function Flow.grid(container, buttons, minWidth, maxColumns, gap, height, changed)
	local grid = Instance.new("UIGridLayout")
	grid.SortOrder, grid.CellPadding, grid.Parent = Enum.SortOrder.LayoutOrder, UDim2.fromOffset(gap,gap), container
	for i,button in ipairs(buttons) do button.Parent,button.LayoutOrder=container,i end
	local function resize()
		local columns,cellWidth,total=Flow.metrics(#buttons,container.AbsoluteSize.X,minWidth,maxColumns,gap,height)
		grid.FillDirectionMaxCells,grid.CellSize=columns,UDim2.fromOffset(cellWidth,height)
		container.Size=UDim2.new(container.Size.X.Scale,container.Size.X.Offset,0,total)
		if changed then changed(total) end
	end
	container:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
	resize()
end
return Flow
