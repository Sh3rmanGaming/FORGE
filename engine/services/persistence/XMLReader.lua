---==========================================================================
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
-- Private Helpers
-----------------------------------------------------------------------------

local function isValidFilePath(filePath)
    return type(filePath) == "string"
        and string.match(filePath, "%S") ~= nil
end

local function isValidVersion(version)
    return type(version) == "number"
        and version == version
        and version ~= math.huge
        and version ~= -math.huge
        and version > 0
        and version == math.floor(version)
end

--- Opens an existing FORGE XML document.
-- @param filePath string
-- @return integer xmlFile
local function openDocument(filePath)
    local callSucceeded, xmlFile = pcall(
        loadXMLFile,
        "FORGEPersistence",
        filePath
    )

    if not callSucceeded
        or xmlFile == nil
        or xmlFile == 0 then
        return 0
    end

    return xmlFile
end

--- Releases an XML resource without allowing cleanup errors to escape.
-- @param xmlFile any
-- @return boolean success
local function releaseDocument(xmlFile)
    if xmlFile == nil or xmlFile == 0 then
        return true
    end

    local callSucceeded = pcall(
        delete,
        xmlFile
    )

    return callSucceeded
end

--- Reads a string attribute safely.
-- @param xmlFile integer
-- @param path string
-- @return boolean success
-- @return string|nil value
local function readString(
    xmlFile,
    path
)
    local callSucceeded, value = pcall(
        getXMLString,
        xmlFile,
        path
    )

    if not callSucceeded then
        return false, nil
    end

    return true, value
end

--- Reads a number attribute safely.
-- @param xmlFile integer
-- @param path string
-- @return boolean success
-- @return number|nil value
local function readNumber(
    xmlFile,
    path
)
    local callSucceeded, value = pcall(
        getXMLFloat,
        xmlFile,
        path
    )

    if not callSucceeded then
        return false, nil
    end

    return true, value
end

--- Reads a boolean attribute safely.
-- @param xmlFile integer
-- @param path string
-- @return boolean success
-- @return boolean|nil value
local function readBoolean(
    xmlFile,
    path
)
    local callSucceeded, value = pcall(
        getXMLBool,
        xmlFile,
        path
    )

    if not callSucceeded then
        return false, nil
    end

    return true, value
end

--- Reads an integer attribute safely.
-- @param xmlFile integer
-- @param path string
-- @return boolean success
-- @return integer|nil value
local function readInteger(
    xmlFile,
    path
)
    local callSucceeded, value = pcall(
        getXMLInt,
        xmlFile,
        path
    )

    if not callSucceeded then
        return false, nil
    end

    return true, value
end

--- Returns whether an XML path exists.
-- @param xmlFile integer
-- @param path string
-- @return boolean success
-- @return boolean exists
local function propertyExists(
    xmlFile,
    path
)
    local callSucceeded, exists = pcall(
        hasXMLProperty,
        xmlFile,
        path
    )

    if not callSucceeded then
        return false, false
    end

    return true, exists == true
end

--- Reads one supported value recursively.
-- @param xmlFile integer
-- @param path string
-- @return boolean success
-- @return any value
local function readValue(
    xmlFile,
    path
)
    local typeRead, valueType =
        readString(
            xmlFile,
            path .. "#type"
        )

    if not typeRead or valueType == nil then
        return false, nil
    end

    if valueType == "string" then
        local valueRead, value =
            readString(
                xmlFile,
                path .. "#value"
            )

        if not valueRead or value == nil then
            return false, nil
        end

        return true, value
    end

    if valueType == "number" then
        local valueRead, value =
            readNumber(
                xmlFile,
                path .. "#value"
            )

        if not valueRead or value == nil then
            return false, nil
        end

        return true, value
    end

    if valueType == "boolean" then
        local valueRead, value =
            readBoolean(
                xmlFile,
                path .. "#value"
            )

        if not valueRead or value == nil then
            return false, nil
        end

        return true, value
    end

    if valueType ~= "table" then
        return false, nil
    end

    local tableValues = {}
    local index = 0

    while true do
        local nestedPath = string.format(
            "%s.value(%d)",
            path,
            index
        )

        local propertyCheckSucceeded, exists =
            propertyExists(
                xmlFile,
                nestedPath
            )

        if not propertyCheckSucceeded then
            return false, nil
        end

        if not exists then
            break
        end

        local keyRead, key =
            readString(
                xmlFile,
                nestedPath .. "#key"
            )

        if not keyRead
            or type(key) ~= "string"
            or string.match(key, "%S") == nil
            or tableValues[key] ~= nil then
            return false, nil
        end

        local valueRead, nestedValue =
            readValue(
                xmlFile,
                nestedPath
            )

        if not valueRead then
            return false, nil
        end

        tableValues[key] = nestedValue
        index = index + 1
    end

    return true, tableValues
end

--- Reads all persisted namespaces.
-- @param xmlFile integer
-- @return boolean success
-- @return table|nil namespaces
local function readNamespaces(xmlFile)
    local namespaces = {}
    local index = 0

    while true do
        local namespacePath = string.format(
            "forge.namespaces.namespace(%d)",
            index
        )

        local propertyCheckSucceeded, exists =
            propertyExists(
                xmlFile,
                namespacePath
            )

        if not propertyCheckSucceeded then
            return false, nil
        end

        if not exists then
            break
        end

        local nameRead, namespace =
            readString(
                xmlFile,
                namespacePath .. "#name"
            )

        if not nameRead
            or type(namespace) ~= "string"
            or string.match(namespace, "%S") == nil
            or namespaces[namespace] ~= nil then
            return false, nil
        end

        local namespaceValues = {}
        local valueIndex = 0

        while true do
            local valuePath = string.format(
                "%s.value(%d)",
                namespacePath,
                valueIndex
            )

            local valuePropertyCheckSucceeded, valueExists =
                    propertyExists(
                        xmlFile,
                        valuePath
                    )

            if not valuePropertyCheckSucceeded then
                return false, nil
            end

            if not valueExists then
                break
            end

            local keyRead, key =
                readString(
                    xmlFile,
                    valuePath .. "#key"
                )

            if not keyRead
                or type(key) ~= "string"
                or string.match(key, "%S") == nil
                or namespaceValues[key] ~= nil then
                return false, nil
            end

            local valueRead, value =
                readValue(
                    xmlFile,
                    valuePath
                )

            if not valueRead then
                return false, nil
            end

            namespaceValues[key] = value
            valueIndex = valueIndex + 1
        end

        namespaces[namespace] =
            namespaceValues

        index = index + 1
    end

    return true, namespaces
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------

--- Reads persistent state from a FORGE XML file.
-- @param filePath any
-- @return boolean success
-- @return table|nil document
function FORGE.XMLReader:read(filePath)
    if not isValidFilePath(filePath) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_READER,
            "Cannot read persistence document using invalid file path '%s'",
            FORGE.Logger:safeToString(
                filePath,
                "<unprintable>"
            )
        )

        return false, nil
    end

    local xmlFile =
        openDocument(filePath)

    if xmlFile == 0 then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_READER,
            "Unable to open persistence document '%s'",
            filePath
        )

        return false, nil
    end

    local versionRead, version =
        readInteger(
            xmlFile,
            "forge#version"
        )

    local namespacesRead = false
    local namespaces = nil

    if versionRead
        and isValidVersion(version) then
        namespacesRead, namespaces =
            readNamespaces(xmlFile)
    end

    local releaseSucceeded =
        releaseDocument(xmlFile)

    if not versionRead
        or not isValidVersion(version) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_READER,
            "Persistence document '%s' has an invalid or missing version",
            filePath
        )

        return false, nil
    end

    if not namespacesRead
        or namespaces == nil then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_READER,
            "Unable to decode persistence document '%s'",
            filePath
        )

        return false, nil
    end

    if not releaseSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_READER,
            "Persistence document '%s' was decoded, but its XML resource could not be released",
            filePath
        )

        return false, nil
    end

    return true, {
        version = version,
        namespaces = namespaces
    }
end