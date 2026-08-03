---=============================================================================
--- FORGE XML Writer
---
--- Serialises approved FORGE runtime state into XML.
---
--- Responsibilities:
---     • Create FORGE persistence documents.
---     • Write persistence-format metadata.
---     • Serialise namespaces and supported values.
---     • Produce deterministic XML output.
---     • Save and release XML resources safely.
---
--- This module must not decide which namespaces are persistent or modify
--- State Store data.
---=============================================================================

FORGE.XMLWriter = {}

-----------------------------------------------------------------------------
-- Private Helpers
-----------------------------------------------------------------------------

local function isValidFilePath(filePath)
    return type(filePath) == "string"
        and string.match(filePath, "%S") ~= nil
end

local function isValidDocument(document)
    if type(document) ~= "table"
        or type(document.version) ~= "number"
        or type(document.namespaces) ~= "table" then
        return false
    end

    return document.version > 0
        and document.version == math.floor(
            document.version
        )
end

local function getSortedKeys(values)
    local sortedKeys = {}

    for key in pairs(values) do
        table.insert(sortedKeys, key)
    end

    table.sort(sortedKeys)

    return sortedKeys
end

--- Creates a new FORGE XML document.
-- @param filePath string
-- @return integer xmlFile
local function createDocument(filePath)
    local success, xmlFile = pcall(
        createXMLFile,
        "FORGEPersistence",
        filePath,
        "forge"
    )

    if not success
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

--- Saves an XML resource without allowing errors to escape.
-- @param xmlFile integer
-- @return boolean success
local function saveDocument(xmlFile)
    if xmlFile == nil or xmlFile == 0 then
        return false
    end

    local callSucceeded, saveSucceeded = pcall(
        saveXMLFile,
        xmlFile
    )

    return callSucceeded
        and saveSucceeded == true
end

--- Writes a string attribute safely.
-- @param xmlFile integer
-- @param path string
-- @param value string
-- @return boolean success
local function writeString(
    xmlFile,
    path,
    value
)
    local callSucceeded = pcall(
        setXMLString,
        xmlFile,
        path,
        value
    )

    return callSucceeded
end

--- Writes a number attribute safely.
-- @param xmlFile integer
-- @param path string
-- @param value number
-- @return boolean success
local function writeNumber(
    xmlFile,
    path,
    value
)
    local callSucceeded = pcall(
        setXMLFloat,
        xmlFile,
        path,
        value
    )

    return callSucceeded
end

--- Writes a boolean attribute safely.
-- @param xmlFile integer
-- @param path string
-- @param value boolean
-- @return boolean success
local function writeBoolean(
    xmlFile,
    path,
    value
)
    local callSucceeded = pcall(
        setXMLBool,
        xmlFile,
        path,
        value
    )

    return callSucceeded
end

--- Writes one supported value recursively.
-- @param xmlFile integer
-- @param path string
-- @param value any
-- @return boolean success
local function writeValue(
    xmlFile,
    path,
    value
)
    local valueType = type(value)

    if not writeString(
        xmlFile,
        path .. "#type",
        valueType
    ) then
        return false
    end

    if valueType == "string" then
        return writeString(
            xmlFile,
            path .. "#value",
            value
        )
    end

    if valueType == "number" then
        return writeNumber(
            xmlFile,
            path .. "#value",
            value
        )
    end

    if valueType == "boolean" then
        return writeBoolean(
            xmlFile,
            path .. "#value",
            value
        )
    end

    if valueType ~= "table" then
        return false
    end

    local sortedKeys =
        getSortedKeys(value)

    for index, nestedKey in ipairs(sortedKeys) do
        local nestedPath = string.format(
            "%s.value(%d)",
            path,
            index - 1
        )

        if not writeString(
            xmlFile,
            nestedPath .. "#key",
            nestedKey
        ) then
            return false
        end

        if not writeValue(
            xmlFile,
            nestedPath,
            value[nestedKey]
        ) then
            return false
        end
    end

    return true
end

--- Writes all namespaces in deterministic alphabetical order.
-- @param xmlFile integer
-- @param namespaces table
-- @return boolean success
local function writeNamespaces(
    xmlFile,
    namespaces
)
    local sortedNamespaces =
        getSortedKeys(namespaces)

    for index, namespace in ipairs(sortedNamespaces) do
        local namespacePath = string.format(
            "forge.namespaces.namespace(%d)",
            index - 1
        )

        if not writeString(
            xmlFile,
            namespacePath .. "#name",
            namespace
        ) then
            return false
        end

        local namespaceValues =
            namespaces[namespace]

        if type(namespaceValues) ~= "table" then
            return false
        end

        local sortedValueKeys =
            getSortedKeys(namespaceValues)

        for valueIndex, key in ipairs(sortedValueKeys) do
            local valuePath = string.format(
                "%s.value(%d)",
                namespacePath,
                valueIndex - 1
            )

            if not writeString(
                xmlFile,
                valuePath .. "#key",
                key
            ) then
                return false
            end

            if not writeValue(
                xmlFile,
                valuePath,
                namespaceValues[key]
            ) then
                return false
            end
        end
    end

    return true
end

--- Writes an integer attribute safely.
-- @param xmlFile integer
-- @param path string
-- @param value integer
-- @return boolean success
local function writeInteger(
    xmlFile,
    path,
    value
)
    local callSucceeded = pcall(
        setXMLInt,
        xmlFile,
        path,
        value
    )

    return callSucceeded
end

-----------------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------------

--- Writes a FORGE persistence document to disk.
-- @param filePath any
-- @param document any
-- @return boolean success
function FORGE.XMLWriter:write(
    filePath,
    document
)
    if not isValidFilePath(filePath) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_WRITER,
            "Cannot write persistence document using invalid file path '%s'",
            FORGE.Logger:safeToString(
                filePath,
                "<unprintable>"
            )
        )

        return false
    end

    if not isValidDocument(document) then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_WRITER,
            "Cannot write invalid persistence document"
        )

        return false
    end

    local xmlFile =
        createDocument(filePath)

    if xmlFile == 0 then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_WRITER,
            "Unable to create persistence document '%s'",
            filePath
        )

        return false
    end

    local writeSucceeded =
        writeInteger(
            xmlFile,
            "forge#version",
            document.version
        )

    if writeSucceeded then
        writeSucceeded =
            writeNamespaces(
                xmlFile,
                document.namespaces
            )
    end

    local saveSucceeded = false

    if writeSucceeded then
        saveSucceeded =
            saveDocument(xmlFile)
    end

    local releaseSucceeded =
        releaseDocument(xmlFile)

    if not writeSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_WRITER,
            "Unable to serialise persistence document '%s'",
            filePath
        )

        return false
    end

    if not saveSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_WRITER,
            "Unable to save persistence document '%s'",
            filePath
        )

        return false
    end

    if not releaseSucceeded then
        FORGE.Logger:error(
            FORGE.Definitions.LogSource.XML_WRITER,
            "Persistence document '%s' was saved, but its XML resource could not be released",
            filePath
        )

        return false
    end

    return true
end