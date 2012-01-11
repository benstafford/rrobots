def closest_target(targets)
  closest = targets[0]
  targets.each {|target| closest = target if target.distance < closest.distance }
  log "closest_target #{closest}\n"
  closest
end

def remove_partner_from_targets(partner, targets)
  targets.delete_if { |target| target.contains(partner) }
end