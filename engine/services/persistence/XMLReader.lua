---=============================================================================
--- FORGE XML Reader
---
--- Deserialises FORGE runtime state from XML.
---
--- Responsibilities:
---     • Open FORGE persistence documents.
---     • Read persistence-format metadata.
---     • Decode namespaces and supported values.
---     • Reject malformed or unsupported data.
---     • Return decoded data without modifying runtime state.
---     • Release XML resources safely.
---
--- This module must not modify the State Store or decide whether loaded data
--- should be applied.
---=============================================================================

FORGE.XMLReader = {}

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------

--- Reads persistent state from a FORGE XML file.
-- @param filePath any
-- @return boolean success
-- @return table|nil document
function FORGE.XMLReader:read(filePath)

end