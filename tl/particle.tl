local vec = require "vec"

global record Particle
    mass: number
    charge: number
    radius: number

    position: Vec3
    velocity: Vec3
    forces: {Vec3}
end

return {
    new = function(args: Particle): Particle
        return {
            mass = args.mass or 1,
            charge = args.charge or 1,
            radius = args.radius or 1,
            position = args.position or vec(0, 0, 0),
            velocity = args.velocity or vec(0, 0, 0),
            forces = args.forces or {}
        }
    end,
    step = function(p: Particle, dt: number)
        local totalForce = vec(0, 0, 0)
        for _, f in ipairs(p.forces) do
            totalForce = totalForce + f
        end
        p.position = p.position + p.velocity * dt
        p.velocity = p.velocity + (totalForce / p.mass)
        p.forces = {}
    end,
    addForce = function(p: Particle, f: Vec3)
        table.insert(p.forces, f)
    end
}
