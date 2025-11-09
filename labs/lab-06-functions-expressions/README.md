# Lab 06: Terraform Functions & Expressions

## Overview

Master Terraform's built-in functions and expressions - heavily tested on the exam. Learn string manipulation, collection operations, conditionals, and advanced expressions.

**Time Estimate:** 35 minutes

### Exam Objectives Covered

- **16a**: String functions (lower, upper, replace, format, join, split)
- **16b**: Collection functions (length, concat, merge, distinct, flatten)
- **16c**: Numeric functions (min, max, ceil, floor)
- **16d**: Type conversion (tostring, tolist, tomap, toset)
- **16e**: Encoding functions (jsonencode, yamlencode, base64encode)
- **16f**: Filesystem functions (file, templatefile)
- **16g**: Hash/crypto functions (md5, sha256, uuid)
- **17a**: Conditional expressions (? :)
- **17b**: For expressions
- **17c**: Splat expressions ([*])
- **18a**: cidrsubnet and cidrhost functions

---

## Function Categories

### String Functions

```hcl
# Case conversion
lower("HELLO")              # "hello"
upper("hello")              # "HELLO"
title("hello world")        # "Hello World"

# Manipulation
trim("  hello  ")           # "hello"
trimspace("  hello  ")      # "hello"
replace("hello", "l", "L")  # "heLLo"
substr("hello", 1, 3)       # "ell"

# Formatting
format("%s-%s", "dev", "01")  # "dev-01"
format("%03d", 5)             # "005"

# Join/Split
join(",", ["a", "b", "c"])    # "a,b,c"
split(",", "a,b,c")           # ["a", "b", "c"]

# Regex
regex("^prod", "production")  # "prod"
can(regex("test", var.env))   # true/false
```

### Collection Functions

```hcl
# List operations
length([1, 2, 3])                    # 3
element([1, 2, 3], 1)                # 2
concat([1, 2], [3, 4])               # [1, 2, 3, 4]
distinct([1, 2, 2, 3])               # [1, 2, 3]
flatten([[1, 2], [3, 4]])            # [1, 2, 3, 4]
compact(["a", "", "b", null])        # ["a", "b"]
reverse([1, 2, 3])                   # [3, 2, 1]
slice([1, 2, 3, 4], 1, 3)            # [2, 3]

# Map operations
keys({a = 1, b = 2})                 # ["a", "b"]
values({a = 1, b = 2})               # [1, 2]
lookup({a = 1}, "b", "default")      # "default"
merge({a = 1}, {b = 2})              # {a = 1, b = 2}

# Create maps
zipmap(["a", "b"], [1, 2])           # {a = 1, b = 2}

# Numeric
min(1, 2, 3)                         # 1
max(1, 2, 3)                         # 3
abs(-5)                              # 5
ceil(3.2)                            # 4
floor(3.8)                           # 3
```

### Type Conversion

```hcl
tostring(123)                  # "123"
tonumber("123")                # 123
tobool("true")                 # true
tolist(["a", "b"])             # ["a", "b"]
toset(["a", "b", "a"])         # ["a", "b"]
tomap({a = 1})                 # {a = 1}
```

### Encoding Functions

```hcl
jsonencode({a = 1, b = 2})     # {"a":1,"b":2}
jsondecode('{"a":1}')          # {a = 1}
yamlencode({a = 1})            # "a: 1\n"
base64encode("hello")          # "aGVsbG8="
base64decode("aGVsbG8=")       # "hello"
```

### Filesystem Functions

```hcl
file("${path.module}/config.txt")                # Read file content

templatefile("${path.module}/template.tpl", {    # Template with variables
  name = "example"
  port = 8080
})

# Path references
path.module                    # Current module path
path.root                      # Root module path
path.cwd                       # Current working directory
```

### Hash/Crypto Functions

```hcl
md5("hello")                   # Hash string
sha256("hello")                # SHA-256 hash
sha512("hello")                # SHA-512 hash
uuid()                         # Generate UUID
uuidv5("dns", "example.com")   # Deterministic UUID
```

### CIDR Functions

```hcl
cidrsubnet("10.0.0.0/16", 8, 0)    # "10.0.0.0/24"
cidrsubnet("10.0.0.0/16", 8, 1)    # "10.0.1.0/24"
cidrhost("10.0.0.0/24", 5)         # "10.0.0.5"
cidrnetmask("10.0.0.0/24")         # "255.255.255.0"
```

---

## Expressions

### Conditional Expression

```hcl
# Syntax: condition ? true_value : false_value

instance_type = var.env == "prod" ? "t2.large" : "t2.micro"

# Nested
instance_count = (
  var.env == "prod" ? 3 :
  var.env == "staging" ? 2 :
  1
)

# With functions
name = can(regex("prod", var.env)) ? upper(var.name) : lower(var.name)
```

### For Expression

**Transform list:**
```hcl
# List comprehension
upper_names = [for name in var.names : upper(name)]

# With filtering
prod_envs = [for env in var.envs : env if env != "dev"]

# With index
indexed = [for i, v in var.list : "${i}-${v}"]
```

**Transform to map:**
```hcl
# List to map
name_map = {
  for name in var.names :
  name => upper(name)
}

# Map transformation
port_map = {
  for k, v in var.ports :
  k => v * 2
}

# Filtering
prod_only = {
  for k, v in var.services :
  k => v if v.env == "prod"
}
```

**Nested for:**
```hcl
# Flatten nested structure
flattened = flatten([
  for sg_name, sg in var.security_groups : [
    for port in sg.ports : {
      sg   = sg_name
      port = port
    }
  ]
])
```

### Splat Expression

```hcl
# Get attribute from all elements
instance_ids = aws_instance.web[*].id

# Equivalent to:
instance_ids = [for i in aws_instance.web : i.id]

# With for_each
subnet_ids = values(aws_subnet.public)[*].id

# Legacy splat (deprecated)
aws_instance.web.*.id  # Use [*] instead
```

---

## Lab Walkthrough

### 1. Deploy and Explore

```bash
cd labs/lab-06-functions-expressions
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

### 2. View Function Results

```bash
# String functions
terraform output string_functions

# Collection functions
terraform output collection_functions

# Conditionals
terraform output conditional_expressions

# For expressions
terraform output for_expressions
```

### 3. Test in Console

```bash
terraform console

# Try string functions
> lower("HELLO")
"hello"

> format("%s-%03d", "web", 5)
"web-005"

# Try collection functions
> concat([1,2], [3,4])
[1, 2, 3, 4]

> distinct([1, 2, 2, 3, 3])
[1, 2, 3]

# Try CIDR functions
> cidrsubnet("10.0.0.0/16", 8, 0)
"10.0.0.0/24"

> cidrhost("10.0.0.0/24", 10)
"10.0.0.10"

# Try conditionals
> "prod" == "prod" ? "large" : "small"
"large"

# Try for expressions
> [for x in [1,2,3] : x * 2]
[2, 4, 6]

> { for x in ["a", "b"] : x => upper(x) }
{
  "a" = "A"
  "b" = "B"
}

> exit
```

### 4. Examine Computed Locals

Check `main.tf` locals block to see real-world function usage:
- String manipulation for naming
- CIDR calculations for subnets
- Conditional logic for environments
- For expressions for transformations
- Filtering and merging collections

---

## Common Patterns

### Dynamic Subnet Creation

```hcl
locals {
  az_subnets = {
    for idx, az in data.aws_availability_zones.available.names :
    az => cidrsubnet(var.vpc_cidr, 8, idx)
  }
}

resource "aws_subnet" "public" {
  for_each = local.az_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
}
```

### Tag Merging

```hcl
locals {
  common_tags = {
    ManagedBy = "Terraform"
    Environment = var.environment
  }

  all_tags = merge(
    local.common_tags,
    var.extra_tags,
    {
      Name = "${var.name_prefix}-${var.environment}"
    }
  )
}
```

### Conditional Resource Creation

```hcl
resource "aws_instance" "bastion" {
  count = var.create_bastion ? 1 : 0
  # ...
}

# Reference: aws_instance.bastion[0].id (if created)
```

### Flatten Nested Structures

```hcl
locals {
  # Input: { web = { ports = [80, 443] }, app = { ports = [8080] } }
  # Output: [{ sg="web", port=80 }, { sg="web", port=443 }, { sg="app", port=8080 }]

  rules = flatten([
    for sg_name, sg in var.security_groups : [
      for port in sg.ports : {
        sg_name = sg_name
        port    = port
      }
    ]
  ])
}
```

---

## Exam Tips

**String Functions:**
- Know `format` for templating
- `join` and `split` for list/string conversion
- `replace` and `regex` for pattern matching

**Collection Functions:**
- `concat` vs `merge` (list vs map)
- `flatten` for nested lists
- `distinct` removes duplicates
- `compact` removes empty/null

**Conditionals:**
- Ternary: `condition ? true_val : false_val`
- Can nest, but keep readable
- Use with `can()` for safe evaluation

**For Expressions:**
- `[for x in list : transform(x)]` → list
- `{for k, v in map : k => transform(v)}` → map
- Add `if` for filtering
- Use with `flatten` for nested structures

**Splat:**
- `[*]` is modern syntax
- Works with count and for_each (via values())
- Gets one attribute from all elements

**CIDR Functions:**
- `cidrsubnet(prefix, newbits, netnum)`
- `cidrhost(prefix, hostnum)`
- Essential for dynamic subnets

**Common Mistakes:**
- Using `*` instead of `[*]` (deprecated)
- Forgetting `can()` with `regex`
- Wrong syntax: `for k, v` not `for v, k`

---

## Cleanup

```bash
terraform destroy
```

---

## Challenge Exercises

### Challenge 1: Complex For Expression
Create a local that transforms the security groups map into a flat list of all rules with their descriptions formatted as "SG_NAME-PORT-PROTOCOL".

### Challenge 2: Conditional Subnet Creation
Modify subnets to only create in specific AZs based on a variable (e.g., only first 2 AZs).

### Challenge 3: Template File Usage
Create a user data template file and use `templatefile()` to populate it with variables.

### Challenge 4: Custom CIDR Logic
Calculate subnet CIDRs that alternate between /24 and /25 based on index.

---

## Key Takeaways

1. **Functions are called, not methods**: `function(arg)` not `arg.function()`
2. **No custom functions**: Use locals for reusable logic
3. **For expressions are powerful**: Learn all forms
4. **Conditionals are ternary only**: No if/else blocks
5. **Splat gets one attribute from all**: `[*].attribute`
6. **Use terraform console**: Best way to test functions
7. **Template files are powerful**: Use for complex strings

---

## Additional Resources

- [Terraform Functions](https://developer.hashicorp.com/terraform/language/functions)
- [Expressions](https://developer.hashicorp.com/terraform/language/expressions)
- [For Expressions](https://developer.hashicorp.com/terraform/language/expressions/for)
- [Splat Expressions](https://developer.hashicorp.com/terraform/language/expressions/splat)
- [Conditional Expressions](https://developer.hashicorp.com/terraform/language/expressions/conditionals)
