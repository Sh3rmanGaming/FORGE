# FORGE Persistence XML Schema

**Version:** 1.0  
**Status:** Stable  
**Persistence Version:** 1

---

# Purpose

This document defines the XML schema used by the FORGE persistence system.

The schema is intentionally simple, deterministic, and independent of gameplay
systems.

Only the XML Writer and XML Reader are permitted to interpret this schema.

---

# File Location

Each savegame contains a FORGE persistence document.

```
savegameX/
└── forge.xml
```

The file is owned exclusively by the FORGE Engine.

---

# Root Element

```xml
<forge version="1">
```

Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| version | Integer | Persistence schema version |

---

# Namespace Collection

```xml
<forge>
    <namespaces>
        ...
    </namespaces>
</forge>
```

Namespaces are written in deterministic alphabetical order.

---

# Namespace

```xml
<namespace name="forge.engine">
```

Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| name | String | Registered State Store namespace |

Each namespace represents one persistent runtime module.

Example

```xml
<namespace name="forge.engine">
    ...
</namespace>
```

---

# Values

Every value contains:

| Attribute | Required | Description |
|-----------|----------|-------------|
| key | Yes | State Store key |
| type | Yes | Runtime value type |
| value | Primitive values only | Serialized primitive value |

Primitive example:

```xml
<value
    key="saveCount"
    type="number"
    value="10.000000"
```

Table values use nested `<value>` elements instead of a `value` attribute:

```xml
<value key="settings" type="table">
    <value
        key="notifications"
        type="boolean"
        value="true"/>
</value>
```

Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| key | String | State Store key |
| type | String | Runtime value type |
| value | Mixed | Serialized value |

---

# Supported Types

The persistence system currently supports:

| Type | Supported |
|------|-----------|
| string | Yes |
| number | Yes |
| boolean | Yes |
| table | Yes |

Unsupported values include:

- functions
- userdata
- threads
- metatables
- cyclic tables
- non-finite numbers (NaN, ±Infinity)

These values are rejected during validation.

---

# Table Serialization

Nested tables are recursively represented using child value nodes.

Example runtime table

```lua
settings = {
    difficulty = "hard",
    notifications = true
}
```

Serialized XML

```xml
<value key="settings" type="table">
    <value
        key="difficulty"
        type="string"
        value="hard"/>

    <value
        key="notifications"
        type="boolean"
        value="true"/>
</value>
```

Table members are written alphabetically.

---

# Example Document

```xml
<?xml version="1.0"?>

<forge version="1">

    <namespaces>

        <namespace name="forge.engine">

            <value
                key="firstRun"
                type="boolean"
                value="false"/>

            <value
                key="saveCount"
                type="number"
                value="10.000000"/>
            <value
                key="saveVersion"
                type="number"
                value="1"/>

        </namespace>

    </namespaces>

</forge>
```

---

# Ordering Rules

To guarantee deterministic output:

- namespaces are sorted alphabetically
- table keys are sorted alphabetically
- repeated saves produce identical output when runtime state has not changed

Deterministic output simplifies:

- debugging
- version control
- regression testing
- schema evolution

---

# Schema Versioning

The XML schema version is stored in the root element.

```xml
<forge version="1">
```

Future schema changes must increment this version.

The Save Manager is responsible for validating compatibility before applying
loaded data.

---

# Ownership

The persistence schema belongs to the FORGE Engine.

Gameplay modules:

- never read XML directly
- never write XML directly
- never depend on XML layout

Gameplay modules interact only with:

- State Store
- Save Manager

This allows the persistence format to evolve without affecting gameplay code.

---

# Stability

Persistence Version 1 was finalized during:

**M1.007 – Persistence**

The schema is considered frozen.

Future changes require:

1. Schema version increment.
2. Backward compatibility strategy.
3. Migration documentation.
4. Regression testing.