local Mirror = {}
function Mirror.apply(plot)
	for _, object in ipairs(plot.model:GetDescendants()) do
		if object:IsA("BasePart") then
			local cf = object.CFrame
			local p, r, u, back = cf.Position - plot.origin, cf.RightVector, cf.UpVector, -cf.LookVector
			object.CFrame = CFrame.fromMatrix(plot.origin + Vector3.new(-p.X, p.Y, p.Z),
				Vector3.new(r.X, -r.Y, -r.Z), Vector3.new(-u.X, u.Y, u.Z), Vector3.new(-back.X, back.Y, back.Z))
			local direction = object:GetAttribute("Direction")
			if direction then
				direction = Vector3.new(-direction.X, direction.Y, direction.Z)
				object:SetAttribute("Direction", direction)
				object.AssemblyLinearVelocity = direction * plot.beltSpeed
			end
		end
	end
	plot.mirrorX = -1
end
return Mirror
