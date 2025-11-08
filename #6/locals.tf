locals {
  # 1. Flatten nested structure
  all_deployments = flatten([
    for service_name, service_config in var.services : [
      for region in service_config.regions : [
        for zone in region.zones : {
          service        = service_name
          region_name    = region.name
          zone           = zone
          replicas       = region.replicas
          tier           = region.tier
          environment    = service_config.environment
          deployment_key = "${service_name}-${region.name}-${zone}"
        }
      ]
    ]
  ])

  all_regions = flatten([
    for service_name, service_config in var.services : [
      for region in service_config.regions : {
        service  = service_name
        tier     = region.tier
        replicas = region.replicas
        name     = region.name
      }
    ]
  ])

  unique_tiers = distinct([
    for region in local.all_regions : region.tier
  ])

  tier_summary = {
    for tier in local.unique_tiers : tier => {
      # Filtruj regiony dla tego tier
      regions = [
        for region in local.all_regions : region if region.tier == tier
      ]

      # Policz total replicas
      total_replicas = sum([
        for region in local.all_regions : region.replicas if region.tier == tier
      ])

      # Policz ile regionów
      region_count = length([
        for region in local.all_regions : region if region.tier == tier
      ])
    }
    }


   prod_services = [
    for service_name, service_config in var.services :
    service_name if service_config.environment == "prod"
  ]

  # 3b. High-replica regions (replicas > 3)
  high_replica_regions = [
    for region in local.all_regions :
    region if region.replicas > 3
  ]

  # 3c. Mapa: region → total instances (all services)
  instances_by_region = {
    for region_name in distinct([for r in local.all_regions : r.region]) :
    region_name => sum([
      for r in local.all_regions : r.replicas if r.region == region_name
    ])
  }

  # 3d. Mapa: region → total instances (only prod services)
  prod_instances_by_region = {
    for region_name in distinct([
      for r in local.all_regions : r.region
      if contains(local.prod_services, r.service)
    ]) :
    region_name => sum([
      for r in local.all_regions : r.replicas
      if r.region == region_name && contains(local.prod_services, r.service)
    ])
  }

  tier_pricing = {
    free     = 0
    standard = 10
    premium  = 50
  }

  # 4b. Dodaj koszt do każdego regionu
  regions_with_cost = [
    for region in local.all_regions : merge(region, {
      cost = region.replicas * local.tier_pricing[region.tier]
    })
  ]

  # 4c. Cost per service-region
  cost_per_region = {
    for region in local.regions_with_cost :
    "${region.service}-${region.region}" => region.cost
  }

  # 4d. Cost per service (total)
  cost_per_service = {
    for service in distinct([for r in local.regions_with_cost : r.service]) :
    service => sum([
      for r in local.regions_with_cost : r.cost if r.service == service
    ])
  }

  # 4e. Total cost across all services
  total_cost = sum([for r in local.regions_with_cost : r.cost])

  # 4f. Bonus: Cost breakdown by tier
  cost_per_tier = {
    for tier in distinct([for r in local.regions_with_cost : r.tier]) :
    tier => sum([
      for r in local.regions_with_cost : r.cost if r.tier == tier
    ])
  }
}
