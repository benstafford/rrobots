def closest_target(sightings)
  closest = sightings[0]
  sightings.each {|target| closest = target if target.distance < closest.distance }
  log "closest_target #{closest}\n"
  closest
end

def remove_partner_from_sightings(partner, targets)
  targets.delete_if { |target| target.contains(partner) }
end