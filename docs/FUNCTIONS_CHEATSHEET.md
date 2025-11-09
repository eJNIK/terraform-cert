# Terraform Functions & Expressions Cheatsheet

Quick reference for Terraform built-in functions, expressions, and operators.

---

## Table of Contents

- [String Functions](#string-functions)
- [Collection Functions](#collection-functions)
- [Numeric Functions](#numeric-functions)
- [Type Conversion](#type-conversion)
- [Encoding Functions](#encoding-functions)
- [Filesystem Functions](#filesystem-functions)
- [Date/Time Functions](#datetime-functions)
- [Hash/Crypto Functions](#hashcrypto-functions)
- [IP Network Functions](#ip-network-functions)
- [Conditional Expressions](#conditional-expressions)
- [For Expressions](#for-expressions)
- [Splat Expressions](#splat-expressions)
- [Operators](#operators)
- [Common Patterns](#common-patterns)

---

## String Functions

### Case Conversion
```hcl
lower("HELLO")              → "hello"
upper("hello")              → "HELLO"
title("hello world")        → "Hello World"
```

### Trimming
```hcl
trim("  hello  ", " ")      → "hello"
trimspace("  hello  ")      → "hello"
trimprefix("helloworld", "hello") → "world"
trimsuffix("helloworld", "world") → "hello"
```

### Manipulation
```hcl
substr("hello", 1, 3)       → "ell"
replace("hello", "l", "L")  → "heLLo"
strrev("hello")             → "olleh"
chomp("hello\n")            → "hello"
```

### Formatting
```hcl
format("%s-%s", "web", "01")     → "web-01"
format("%03d", 5)                → "005"
format("%.2f", 3.14159)          → "3.14"
```

### Join/Split
```hcl
join(",", ["a", "b", "c"])       → "a,b,c"
split(",", "a,b,c")              → ["a", "b", "c"]
```

### Regex
```hcl
regex("^prod", "production")                    → "prod"
regexall("\\d+", "abc123def456")                → ["123", "456"]
can(regex("prod", var.env))                     → true/false (safe check)
```

### Indent
```hcl
indent(4, "hello\nworld")   → "    hello\n    world"
```

---

## Collection Functions

### List Operations
```hcl
# Basic
length([1, 2, 3])                    → 3
element([1, 2, 3], 1)                → 2
index(["a", "b", "c"], "b")          → 1
contains(["a", "b"], "a")            → true

# Modification
concat([1, 2], [3, 4])               → [1, 2, 3, 4]
distinct([1, 2, 2, 3])               → [1, 2, 3]
flatten([[1, 2], [3, 4]])            → [1, 2, 3, 4]
compact(["a", "", "b", null])        → ["a", "b"]
reverse([1, 2, 3])                   → [3, 2, 1]
sort(["c", "a", "b"])                → ["a", "b", "c"]

# Slice/Chunk
slice([1, 2, 3, 4], 1, 3)            → [2, 3]
chunklist([1, 2, 3, 4, 5], 2)        → [[1, 2], [3, 4], [5]]

# Range
range(3)                             → [0, 1, 2]
range(1, 4)                          → [1, 2, 3]
range(0, 6, 2)                       → [0, 2, 4]

# Set Operations
setintersection([1,2,3], [2,3,4])    → [2, 3]
setunion([1,2], [2,3])               → [1, 2, 3]
setsubtract([1,2,3], [2])            → [1, 3]
setproduct([1,2], ["a","b"])         → [[1,"a"],[1,"b"],[2,"a"],[2,"b"]]
```

### Map Operations
```hcl
# Access
keys({a = 1, b = 2})                 → ["a", "b"]
values({a = 1, b = 2})               → [1, 2]
lookup({a = 1}, "b", "default")      → "default"

# Modification
merge({a = 1}, {b = 2})              → {a = 1, b = 2}
merge({a = 1}, {a = 2})              → {a = 2} (last wins)

# Create
zipmap(["a", "b"], [1, 2])           → {a = 1, b = 2}

# Transform
matchkeys(
  ["i-123", "i-456"],                # values
  ["us-east-1a", "us-east-1b"],      # keys
  ["us-east-1a"]                     # searchset
)                                    → ["i-123"]
```

### Type Checks
```hcl
can(var.value)                       → true if value valid, false otherwise
try(var.maybe_null, "default")       → var if valid, "default" if error
```

---

## Numeric Functions

### Basic Math
```hcl
abs(-5)                              → 5
ceil(3.2)                            → 4
floor(3.8)                           → 3
```

### Min/Max
```hcl
min(1, 2, 3)                         → 1
max(1, 2, 3)                         → 3
min([1, 2, 3]...)                    → 1  (with splat)
```

### Power/Log
```hcl
pow(2, 3)                            → 8
log(16, 2)                           → 4
```

### Parse
```hcl
parseint("100", 10)                  → 100
parseint("FF", 16)                   → 255
```

---

## Type Conversion

```hcl
# To String
tostring(123)                        → "123"
tostring(true)                       → "true"

# To Number
tonumber("123")                      → 123

# To Bool
tobool("true")                       → true
tobool("false")                      → false

# To List
tolist(["a", "b"])                   → ["a", "b"]
tolist(toset(["a", "a", "b"]))       → ["a", "b"]

# To Set (removes duplicates)
toset(["a", "b", "a"])               → ["a", "b"]

# To Map
tomap({a = 1, b = 2})                → {a = 1, b = 2}

# Type checking
type(var.value)                      → "string", "number", "bool", "list", "map", "set", "object", "tuple"
```

---

## Encoding Functions

### JSON
```hcl
jsonencode({a = 1, b = 2})           → "{\"a\":1,\"b\":2}"
jsondecode('{"a":1,"b":2}')          → {a = 1, b = 2}
```

### YAML
```hcl
yamlencode({a = 1, b = 2})           → "a: 1\nb: 2\n"
yamldecode("a: 1\nb: 2")             → {a = 1, b = 2}
```

### Base64
```hcl
base64encode("hello")                → "aGVsbG8="
base64decode("aGVsbG8=")             → "hello"
base64gzip("hello")                  → compressed + base64
```

### URL
```hcl
urlencode("hello world")             → "hello+world"
urldecode("hello+world")             → "hello world"
```

### CSV
```hcl
csvdecode("a,b,c\n1,2,3")            → [{a="1", b="2", c="3"}]
```

---

## Filesystem Functions

### Read Files
```hcl
file("${path.module}/config.txt")              # Read file as string
fileexists("${path.module}/config.txt")        # true/false
fileset("${path.module}", "*.tf")              # ["main.tf", "variables.tf"]
```

### Templates
```hcl
templatefile("${path.module}/template.tpl", {
  name = "example"
  port = 8080
})
```

### Paths
```hcl
path.module                          # Current module directory
path.root                            # Root module directory
path.cwd                             # Current working directory

dirname("/foo/bar/baz.txt")          → "/foo/bar"
basename("/foo/bar/baz.txt")         → "baz.txt"
abspath("../relative/path")          → "/absolute/path"
```

---

## Date/Time Functions

```hcl
timestamp()                          → "2024-01-15T10:30:00Z"
timeadd("2024-01-15T10:30:00Z", "1h") → "2024-01-15T11:30:00Z"
timecmp("2024-01-15T10:30:00Z", "2024-01-15T11:30:00Z") → -1

formatdate("YYYY-MM-DD", timestamp())           → "2024-01-15"
formatdate("DD MMM YYYY hh:mm:ss", timestamp()) → "15 Jan 2024 10:30:00"

plantimestamp()                      → timestamp of current plan (stable during plan)
```

---

## Hash/Crypto Functions

```hcl
# Hashing
md5("hello")                         → "5d41402abc4b2a76b9719d911017c592"
sha1("hello")                        → "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d"
sha256("hello")                      → "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
sha512("hello")                      → (64 character hash)

# Base64 hashing
base64sha256("hello")                → base64 encoded SHA256
base64sha512("hello")                → base64 encoded SHA512

# UUID
uuid()                               → "550e8400-e29b-41d4-a716-446655440000"
uuidv5("dns", "example.com")         → deterministic UUID
```

### File Hashing
```hcl
filemd5("${path.module}/file.txt")
filesha256("${path.module}/file.txt")
filebase64sha256("${path.module}/file.txt")
```

---

## IP Network Functions

### CIDR Operations
```hcl
# Subnet calculation
cidrsubnet("10.0.0.0/16", 8, 0)      → "10.0.0.0/24"
cidrsubnet("10.0.0.0/16", 8, 1)      → "10.0.1.0/24"
cidrsubnet("10.0.0.0/16", 8, 2)      → "10.0.2.0/24"

# Host calculation
cidrhost("10.0.0.0/24", 5)           → "10.0.0.5"
cidrhost("10.0.0.0/24", 255)         → "10.0.0.255"

# Netmask
cidrnetmask("10.0.0.0/24")           → "255.255.255.0"

# CIDR range split
cidrsubnets("10.0.0.0/16", 4, 4, 8, 4) → [
  "10.0.0.0/20",
  "10.0.16.0/20",
  "10.0.32.0/24",
  "10.0.48.0/20"
]
```

---

## Conditional Expressions

### Ternary Operator
```hcl
condition ? true_value : false_value
```

### Examples
```hcl
# Simple
instance_type = var.env == "prod" ? "t2.large" : "t2.micro"

# Nested
instance_count = (
  var.env == "prod"    ? 3 :
  var.env == "staging" ? 2 :
  1
)

# With functions
name = can(regex("prod", var.env)) ? upper(var.name) : lower(var.name)

# Multiple conditions (AND)
result = var.enabled && var.env == "prod" ? "yes" : "no"

# Multiple conditions (OR)
result = var.env == "prod" || var.env == "staging" ? "yes" : "no"

# Null coalescing
value = var.optional != null ? var.optional : "default"

# Better with try/coalesce
value = try(var.optional, "default")
value = coalesce(var.maybe_null, var.maybe_null_2, "default")
```

---

## For Expressions

### List Comprehension
```hcl
# Transform
[for item in list : transform(item)]

# Examples
[for name in var.names : upper(name)]
[for port in [80, 443, 8080] : "Port ${port}"]
[for i in range(3) : "server-${i}"]

# With index
[for i, v in var.list : "${i}: ${v}"]

# Filter with if
[for name in var.names : upper(name) if name != ""]
[for env in ["dev", "staging", "prod"] : env if env != "dev"]

# Complex transform
[for instance in var.instances : {
  name = instance.name
  type = instance.type
  id   = instance.id
}]
```

### Map Comprehension
```hcl
# Transform list to map
{for item in list : key_expression => value_expression}

# Examples
{for name in var.names : name => upper(name)}
{for i, v in var.list : i => v}

# Transform map to map
{for k, v in map : k => transform(v)}

# Example
{for name, config in var.instances : name => config.type}

# Filter
{for k, v in var.map : k => v if v.enabled}

# With ellipsis (grouping)
{for s in var.list : s.key => s.value...}
```

### Nested For
```hcl
# Flatten nested structure
flatten([
  for sg_name, sg in var.security_groups : [
    for port in sg.ports : {
      sg_name = sg_name
      port    = port
    }
  ]
])

# Result: flat list of all sg/port combinations
```

---

## Splat Expressions

### Basic Splat
```hcl
# Get single attribute from all elements
resource.name[*].attribute

# Examples
aws_instance.web[*].id
aws_subnet.public[*].cidr_block
```

### With For_Each
```hcl
# For_each returns map, need values()
values(aws_subnet.public)[*].id

# Or use for expression
[for subnet in aws_subnet.public : subnet.id]
```

### Legacy Splat (deprecated)
```hcl
aws_instance.web.*.id        # Old syntax
aws_instance.web[*].id       # New syntax (use this)
```

### Full Splat
```hcl
# Get all attributes (rare usage)
aws_instance.web[*]
```

---

## Operators

### Arithmetic
```hcl
a + b      # Addition
a - b      # Subtraction
a * b      # Multiplication
a / b      # Division
a % b      # Modulo
-a         # Negation
```

### Comparison
```hcl
a == b     # Equal
a != b     # Not equal
a < b      # Less than
a > b      # Greater than
a <= b     # Less than or equal
a >= b     # Greater than or equal
```

### Logical
```hcl
a && b     # AND
a || b     # OR
!a         # NOT
```

### String
```hcl
"Hello, ${var.name}"         # Interpolation
"${var.a}${var.b}"           # Concatenation
```

---

## Common Patterns

### Safe Attribute Access
```hcl
# Use try for optional attributes
instance_id = try(aws_instance.web[0].id, null)

# Use can to check if valid
is_valid = can(regex("prod", var.env))
```

### Dynamic Blocks
```hcl
dynamic "ingress" {
  for_each = var.ingress_rules

  content {
    from_port   = ingress.value.port
    to_port     = ingress.value.port
    protocol    = ingress.value.protocol
    cidr_blocks = ingress.value.cidrs
  }
}
```

### Conditional Resource Creation
```hcl
# With count
resource "aws_instance" "example" {
  count = var.create ? 1 : 0
  # ...
}

# With for_each
resource "aws_instance" "example" {
  for_each = var.create ? var.instances : {}
  # ...
}
```

### Filtering Collections
```hcl
# Filter map
enabled_instances = {
  for k, v in var.instances : k => v
  if v.enabled
}

# Filter list
active_users = [
  for user in var.users : user
  if user.status == "active"
]
```

### Merging Tags
```hcl
locals {
  common_tags = {
    ManagedBy   = "Terraform"
    Environment = var.environment
  }

  resource_tags = merge(
    local.common_tags,
    var.extra_tags,
    {
      Name = "${var.name_prefix}-${var.environment}"
    }
  )
}
```

### Dynamic Subnets Across AZs
```hcl
locals {
  subnet_map = {
    for idx, az in data.aws_availability_zones.available.names :
    az => cidrsubnet(var.vpc_cidr, 8, idx)
  }
}

resource "aws_subnet" "public" {
  for_each = local.subnet_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
}
```

### Flatten Nested Structures
```hcl
# Input: { web = { ports = [80, 443] }, app = { ports = [8080] } }
# Output: [{ sg="web", port=80 }, { sg="web", port=443 }, ...]

locals {
  security_rules = flatten([
    for sg_name, sg in var.security_groups : [
      for port in sg.ports : {
        sg_name = sg_name
        port    = port
      }
    ]
  ])
}
```

### Lookup with Default
```hcl
instance_type = lookup(
  {
    dev     = "t2.micro"
    staging = "t2.small"
    prod    = "t2.large"
  },
  var.environment,
  "t2.micro"  # default
)
```

### Coalesce for Null Handling
```hcl
# Return first non-null value
value = coalesce(var.optional_1, var.optional_2, "default")

# Similar with try
value = try(var.might_fail, var.backup, "default")
```

### Contains Check
```hcl
is_production = contains(["prod", "production"], var.environment)

# Use in conditional
instance_count = contains(["prod", "production"], var.env) ? 3 : 1
```

### Distinct and Sort
```hcl
# Remove duplicates
unique_ports = distinct([80, 443, 80, 8080, 443])  # [80, 443, 8080]

# Sort list
sorted_envs = sort(["prod", "dev", "staging"])     # ["dev", "prod", "staging"]
```

---

## Quick Tips

1. **Functions are called, not methods**: `lower(string)` not `string.lower()`
2. **No custom functions**: Use `locals` for reusable logic
3. **Test in console**: `terraform console` is your friend
4. **can() for safety**: Wrap risky operations in `can()`
5. **try() for defaults**: Better than multiple conditionals
6. **Splat is modern**: Use `[*]` not `.*`
7. **For is powerful**: Learn all variations
8. **Watch precedence**: Use parentheses for clarity

---

## Exam Focus

**Most Tested:**
- `cidrsubnet` and `cidrhost`
- for expressions (all forms)
- Conditional expressions
- `merge`, `concat`, `flatten`
- `lookup` with default
- `jsonencode`
- String interpolation

**Common Mistakes:**
- Using `*` instead of `[*]`
- Wrong for syntax: `for v, k` (should be `for k, v`)
- Forgetting `can()` with `regex`
- Not using `try()` for optional values
- Confusing `concat` (lists) with `merge` (maps)

---

## Additional Resources

- [Official Functions Docs](https://developer.hashicorp.com/terraform/language/functions)
- [Expressions Docs](https://developer.hashicorp.com/terraform/language/expressions)
- [For Expressions](https://developer.hashicorp.com/terraform/language/expressions/for)
