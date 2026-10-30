---=============================================================================
--- FORGE Declarative Presentation Runtime
---
--- Validates, detaches, lays out, renders, and hit-tests frozen PF.001 model-v2
--- presentation data. It contains no application or gameplay-domain branches.
---=============================================================================

FORGE.PresentationRenderer = {}

local Renderer = FORGE.PresentationRenderer
local D = FORGE.Definitions
local Limit = D.PresentationLimit
local Contracts = D.PresentationComponentContract

local directions = { vertical = true, horizontal = true }
local alignments = { start = true, center = true, ["end"] = true, stretch = true }
local distributions = { start = true, center = true, ["end"] = true,
    spaceBetween = true }
local sizeModes = { auto = true, content = true, fill = true, weighted = true }
local clips = { none = true, bounds = true }
local overflows = { visible = true, hidden = true, scroll = true }
local wraps = { none = true, word = true }
local textOverflows = { clip = true, ellipsis = true }
local textAlignments = { start = true, center = true, ["end"] = true }
local states = { none = true, unread = true, attention = true, success = true,
    warning = true, error = true, information = true }
local targets = { application = true, host = true }
local hostActions = { osHome = true, deviceClose = true }

local tokenCategories = {
    spacing = {}, size = {}, surface = {}, border = {}, typography = {}
}
for _, value in pairs(D.PresentationToken or {}) do
    if type(value) == "string" then
        local prefix = string.match(value, "^([^.]+)%.")
        if tokenCategories[prefix] ~= nil then
            tokenCategories[prefix][value] = true
        end
    end
end
for _, value in pairs(D.PresentationSizeToken or {}) do
    tokenCategories.size[value] = true
end

local propertyCategory = {
    spacing = "spacing", padding = "spacing", gap = "spacing",
    minimumWidth = "size", maximumWidth = "size",
    minimumHeight = "size", maximumHeight = "size",
    surface = "surface", border = "border", textRole = "typography"
}
local sizeRank = { ["size.xs"] = 1, ["size.sm"] = 2, ["size.md"] = 3,
    ["size.lg"] = 4, ["size.xl"] = 5, ["size.xxl"] = 6,
    ["size.viewport"] = 7 }

local function scanDetached(value, seen)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "string" then return true end
    if kind == "number" then
        return value == value and value ~= math.huge and value ~= -math.huge
    end
    if kind ~= "table" or getmetatable(value) ~= nil or seen[value] then return false end
    seen[value] = true
    for key, nested in pairs(value) do
        if type(key) ~= "string" and (type(key) ~= "number" or key < 1
            or key ~= math.floor(key)) then return false end
        if not scanDetached(nested, seen) then return false end
    end
    return true
end

local function identifier(value)
    return type(value) == "string" and value ~= ""
        and string.find(value, "%s") == nil
end

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function plainTable(value)
    return type(value) == "table" and getmetatable(value) == nil
end

local function contiguous(value, maximum)
    if not plainTable(value) then return nil end
    local count = 0
    for index in ipairs(value) do count = index end
    if maximum ~= nil and count > maximum then return nil end
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key > count
            or key ~= math.floor(key) then return nil end
    end
    return count
end

local function equalPlain(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    seen = seen or {}
    if seen[left] == right then return true end
    seen[left] = right
    for key, value in pairs(left) do
        if not equalPlain(value, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function copyControlled(value, state, depth)
    local kind = type(value)
    if kind == "nil" or kind == "boolean" or kind == "string" then
        return true, value
    end
    if kind == "number" then return finite(value), value end
    if kind ~= "table" or getmetatable(value) ~= nil
        or state.seen[value] or depth > Limit.MAX_PARAMETER_DEPTH then
        return false, nil
    end
    state.seen[value] = true
    local copy = {}
    for key, nested in pairs(value) do
        if type(key) ~= "string" then return false, nil end
        state.entries = state.entries + 1
        if state.entries > Limit.MAX_PARAMETER_ENTRIES then return false, nil end
        local ok, detached = copyControlled(nested, state, depth + 1)
        if not ok then return false, nil end
        copy[key] = detached
    end
    return true, copy
end

local function validateAction(action, presentation)
    if not plainTable(action) then return nil end
    for key in pairs(action) do
        if key ~= "target" and key ~= "actionId" and key ~= "parameters" then
            return nil
        end
    end
    if not targets[action.target] or not identifier(action.actionId) then return nil end
    if action.target == "host" then
        if not hostActions[action.actionId] then return nil end
    elseif presentation.actions == nil
        or presentation.actions[action.actionId] == nil then return nil end
    local ok, parameters = copyControlled(action.parameters or {},
        { seen = {}, entries = 0 }, 1)
    if not ok then return nil end
    return { target = action.target, actionId = action.actionId,
        parameters = parameters }
end

local function validateProperty(name, value, contract)
    local category = propertyCategory[name]
    if category ~= nil then return tokenCategories[category][value] == true end
    if name == "text" or name == "accessibleLabel" then
        return type(value) == "string" and #value <= Limit.MAX_TEXT_LENGTH
    end
    if name == "iconId" then return identifier(value) end
    if name == "direction" then return directions[value] == true end
    if name == "alignment" then return alignments[value] == true end
    if name == "distribution" then return distributions[value] == true end
    if name == "widthMode" or name == "heightMode" then
        return sizeModes[value] == true
    end
    if name == "grow" then return value == 1 or value == 2 or value == 3 or value == 4 end
    if name == "clipping" then return clips[value] == true end
    if name == "overflow" then return overflows[value] == true end
    if name == "textWrap" then return wraps[value] == true end
    if name == "textOverflow" then return textOverflows[value] == true end
    if name == "textAlignment" then return textAlignments[value] == true end
    if name == "maximumLines" then
        return finite(value) and value >= 1 and value == math.floor(value)
            and value <= Limit.MAXIMUM_TEXT_LINES
    end
    if name == "selected" or name == "disabled" then return type(value) == "boolean" end
    if name == "count" then
        return finite(value) and value >= 0 and value == math.floor(value)
    end
    if name == "semanticState" then
        if not states[value] then return false end
        for _, allowed in ipairs(contract.allowedSemanticStates) do
            if value == allowed then return true end
        end
        return false
    end
    return name == "actionReference"
end

local function validateNode(node, state, depth, presentation, actions, interactiveParent)
    if not plainTable(node) or depth > Limit.MAX_VIEW_DEPTH or state.seen[node] then
        return nil
    end
    state.seen[node] = true
    state.nodes = state.nodes + 1
    if state.nodes > Limit.MAX_VIEW_NODES then return nil end
    for key in pairs(node) do
        if key ~= "component" and key ~= "id" and key ~= "properties"
            and key ~= "children" then return nil end
    end
    local contract = Contracts[node.component]
    if contract == nil or (node.id ~= nil and not identifier(node.id)) then return nil end
    if node.id ~= nil then
        if state.ids[node.id] then return nil end
        state.ids[node.id] = true
    end
    if interactiveParent and contract.interactive then return nil end
    local properties = node.properties or {}
    if not plainTable(properties) or state.seen[properties] then return nil end
    state.seen[properties] = true
    local allowed = {}
    for _, name in ipairs(contract.allowedProperties) do allowed[name] = true end
    for _, name in ipairs(contract.requiredProperties) do
        if properties[name] == nil then return nil end
    end
    local copyProperties = {}
    for name, value in pairs(properties) do
        if type(name) ~= "string" or not allowed[name]
            or not validateProperty(name, value, contract) then return nil end
        if name == "actionReference" then
            local action = validateAction(value, presentation)
            if action == nil then return nil end
            local matches = 0
            for _, offered in ipairs(actions) do
                if equalPlain(action, offered) then matches = matches + 1 end
            end
            if matches ~= 1 then return nil end
            copyProperties[name] = action
        else
            copyProperties[name] = value
        end
    end
    if properties.minimumWidth ~= nil and properties.maximumWidth ~= nil
        and sizeRank[properties.minimumWidth] > sizeRank[properties.maximumWidth] then
        return nil
    end
    if properties.minimumHeight ~= nil and properties.maximumHeight ~= nil
        and sizeRank[properties.minimumHeight] > sizeRank[properties.maximumHeight] then
        return nil
    end
    if contract.interactive ~= (properties.actionReference ~= nil) then return nil end
    local childCount = node.children ~= nil
        and contiguous(node.children, Limit.MAX_CHILDREN_PER_NODE) or nil
    if contract.childPolicy == "forbidden" and node.children ~= nil then return nil end
    if contract.childPolicy == "required" and childCount == nil then return nil end
    if node.children ~= nil and childCount == nil then return nil end
    childCount = childCount or 0
    if childCount < contract.minimumChildren or childCount > contract.maximumChildren then
        return nil
    end
    if contract.contentSources ~= nil then
        local content = childCount > 0 and 1 or 0
        for _, name in ipairs(contract.contentSources) do
            if name ~= "children" and properties[name] ~= nil then content = content + 1 end
        end
        if content < contract.minimumContentSources then return nil end
    end
    local children = {}
    for index = 1, childCount do
        local child = validateNode(node.children[index], state, depth + 1,
            presentation, actions, interactiveParent or contract.interactive)
        if child == nil then return nil end
        children[index] = child
    end
    return { component = node.component, id = node.id,
        properties = copyProperties, children = children }
end

function Renderer.validateModel(model, context, presentation)
    if not plainTable(model) or not scanDetached(model, {}) then return nil end
    local allowed = { modelVersion = true, appId = true, presentationId = true,
        routeId = true, title = true, attention = true, view = true, actions = true }
    for key in pairs(model) do if not allowed[key] then return nil end end
    if model.modelVersion ~= 2 or model.appId ~= context.appId
        or model.presentationId ~= context.presentationId
        or model.routeId ~= context.routeId or type(model.title) ~= "string"
        or #model.title > Limit.MAX_TEXT_LENGTH then return nil end
    local actionCount = contiguous(model.actions, Limit.MAX_ACTIONS)
    if actionCount == nil then return nil end
    local actions, seenActions = {}, {}
    for index = 1, actionCount do
        local action = validateAction(model.actions[index], presentation)
        if action == nil then return nil end
        local signature = action.target .. "\0" .. action.actionId
            .. "\0" .. tostring(index)
        for _, existing in ipairs(actions) do
            if equalPlain(action, existing) then return nil end
        end
        seenActions[signature] = true
        actions[index] = action
    end
    local view = validateNode(model.view,
        { seen = {}, ids = {}, nodes = 0 }, 1, presentation, actions, false)
    if view == nil then return nil end
    local attention = nil
    if model.attention ~= nil then
        if not plainTable(model.attention) then return nil end
        for key in pairs(model.attention) do
            if key ~= "state" and key ~= "count" and key ~= "accessibleLabel" then
                return nil
            end
        end
        if not states[model.attention.state or "none"]
            or model.attention.count ~= nil and (not finite(model.attention.count)
                or model.attention.count < 0
                or model.attention.count ~= math.floor(model.attention.count))
            or model.attention.accessibleLabel ~= nil
                and (type(model.attention.accessibleLabel) ~= "string"
                    or #model.attention.accessibleLabel > Limit.MAX_TEXT_LENGTH) then
            return nil
        end
        local ok, copy = copyControlled(model.attention,
            { seen = {}, entries = 0 }, 1)
        if not ok then return nil end
        attention = copy
    end
    return { modelVersion = 2, appId = model.appId,
        presentationId = model.presentationId, routeId = model.routeId,
        title = model.title, attention = attention, view = view, actions = actions }
end

local function intersect(a, b)
    local x1, y1 = math.max(a.x, b.x), math.max(a.y, b.y)
    local x2 = math.min(a.x + a.width, b.x + b.width)
    local y2 = math.min(a.y + a.height, b.y + b.height)
    return { x = x1, y = y1, width = math.max(0, x2 - x1),
        height = math.max(0, y2 - y1) }
end

local function metric(profile, category, token)
    if token == nil then return 0 end
    local values = profile[category]
    return values ~= nil and values[token] or nil
end

local function requiredMetric(profile, category, token)
    if token == nil then return 0 end
    local value = metric(profile, category, token)
    if value == nil then error("missing " .. category .. " mapping") end
    return value
end

local function wrapText(text, width, measure)
    local lines, line = {}, ""
    if width <= 0 then return lines end
    text = string.gsub(string.gsub(text, "\r\n", "\n"), "\r", "\n")
    for word, separator in string.gmatch(text .. " ", "([^%s\n]*)([%s\n]+)") do
        local candidate = line == "" and word or line .. " " .. word
        if word ~= "" and measure(candidate) > width and line ~= "" then
            lines[#lines + 1], line = line, word
        else
            line = candidate
        end
        if string.find(separator, "\n") then lines[#lines + 1], line = line, "" end
    end
    if line ~= "" or #lines == 0 then lines[#lines + 1] = line end
    return lines
end

local function ellipsize(text, width, measure, glyph)
    if measure(text) <= width then return text end
    local low, high = 0, #text
    while low < high do
        local middle = math.ceil((low + high) / 2)
        if measure(string.sub(text, 1, middle) .. glyph) <= width then
            low = middle else high = middle - 1 end
    end
    while low > 0 do
        local byte = string.byte(text, low)
        if byte == nil or byte < 128 or byte >= 192 then break end
        low = low - 1
    end
    return string.sub(text, 1, low) .. glyph
end

local function clampSize(value, minimum, maximum)
    if minimum ~= nil then value = math.max(value, minimum) end
    if maximum ~= nil then value = math.min(value, maximum) end
    return math.max(0, value)
end

local function measureNode(node, availableWidth, profile, backend)
    local p, component = node.properties, node.component
    local padding = requiredMetric(profile, "spacing", p.padding)
    local gap = requiredMetric(profile, "spacing", p.gap)
    local width, height = 0, 0
    if p.text ~= nil then
        local font = profile.typography[p.textRole or "typography.body"]
        if font == nil then error("missing typography mapping") end
        local usable = math.max(0, availableWidth - padding * 2)
        local measure = function(value) return backend.measureText(value, font) end
        local lines = (p.textWrap or "none") == "word"
            and wrapText(p.text, usable, measure) or { p.text }
        local visible = math.min(#lines, p.maximumLines or #lines)
        height = visible * font.lineHeight + padding * 2
        for index = 1, visible do width = math.max(width, measure(lines[index])) end
        width = width + padding * 2
    elseif p.iconId ~= nil then
        local iconSize = profile.iconSize or 0.03
        width, height = iconSize + padding * 2, iconSize + padding * 2
    elseif p.count ~= nil then
        local font = profile.typography["typography.numeric"]
        width = backend.measureText(tostring(p.count), font) + padding * 2
        height = font.lineHeight + padding * 2
    end
    local horizontal = component == "layout.row"
        or component == "layout.split" and (p.direction or "horizontal") == "horizontal"
        or component == "control.button" or component == "control.navigationItem"
        or component == "control.listRow" or component == "indicator.status"
    if #node.children > 0 then
        local childWidth, childHeight = 0, 0
        for _, child in ipairs(node.children) do
            local measured = measureNode(child, math.max(0, availableWidth - padding * 2),
                profile, backend)
            if horizontal then
                childWidth, childHeight = childWidth + measured.width,
                    math.max(childHeight, measured.height)
            else
                childWidth, childHeight = math.max(childWidth, measured.width),
                    childHeight + measured.height
            end
        end
        if horizontal then childWidth = childWidth + gap * (#node.children - 1)
        else childHeight = childHeight + gap * (#node.children - 1) end
        width, height = math.max(width, childWidth + padding * 2),
            math.max(height, childHeight + padding * 2)
    end
    local minimumWidth = p.minimumWidth ~= nil
        and requiredMetric(profile, "sizes", p.minimumWidth) or nil
    local maximumWidth = p.maximumWidth ~= nil
        and requiredMetric(profile, "sizes", p.maximumWidth) or nil
    local minimumHeight = p.minimumHeight ~= nil
        and requiredMetric(profile, "sizes", p.minimumHeight) or nil
    local maximumHeight = p.maximumHeight ~= nil
        and requiredMetric(profile, "sizes", p.maximumHeight) or nil
    return { width = clampSize(width, minimumWidth, maximumWidth),
        height = clampSize(height, minimumHeight, maximumHeight) }
end

local function layoutNode(node, bounds, clip, profile, backend, session, plan, path)
    local p, component = node.properties, node.component
    local padding = requiredMetric(profile, "spacing", p.padding)
    local gap = requiredMetric(profile, "spacing", p.gap)
    if p.surface ~= nil and (profile.surfaces == nil
        or profile.surfaces[p.surface] == nil) then error("missing surface mapping") end
    if p.border ~= nil and (profile.borders == nil
        or profile.borders[p.border] == nil) then error("missing border mapping") end
    if p.semanticState ~= nil and p.semanticState ~= "none"
        and (profile.semantic == nil or profile.semantic[p.semanticState] == nil) then
        error("missing semantic-state mapping")
    end
    local ownClip = (p.clipping or "bounds") == "bounds"
        or (p.overflow or "hidden") ~= "visible"
    local effectiveClip = ownClip and intersect(clip, bounds) or clip
    plan.ordinal = plan.ordinal + 1
    plan.primitives[#plan.primitives + 1] = { kind = "box", component = component,
        bounds = bounds, clip = effectiveClip, properties = p, ordinal = plan.ordinal }
    if component == "content.text" then
        local role = p.textRole or "typography.body"
        local font = profile.typography[role]
        if font == nil then error("missing typography mapping") end
        local width = math.max(0, bounds.width - padding * 2)
        local measure = function(value) return backend.measureText(value, font) end
        local lines = (p.textWrap or "none") == "word"
            and wrapText(p.text, width, measure) or { p.text }
        local maximum = p.maximumLines or #lines
        for index = 1, math.min(#lines, maximum) do
            local value = lines[index]
            if (p.textOverflow or "clip") == "ellipsis"
                and (measure(value) > width or index == maximum and #lines > maximum) then
                value = ellipsize(value, width, measure, profile.ellipsis or "...")
            end
            plan.primitives[#plan.primitives + 1] = { kind = "text", text = value,
                x = bounds.x + padding, y = bounds.y + bounds.height - padding
                    - index * font.lineHeight, font = font, clip = effectiveClip,
                state = p.semanticState or "none", ordinal = plan.ordinal }
        end
    end
    if component ~= "content.text" and p.text ~= nil then
        local font = profile.typography[p.textRole or "typography.body"]
        if font == nil then error("missing typography mapping") end
        plan.primitives[#plan.primitives + 1] = { kind = "text", text = p.text,
            x = bounds.x + padding, y = bounds.y + bounds.height - padding
                - font.lineHeight, font = font, clip = effectiveClip,
            state = p.semanticState or "none", ordinal = plan.ordinal }
    end
    if p.count ~= nil then
        local font = profile.typography["typography.numeric"]
        plan.primitives[#plan.primitives + 1] = { kind = "text",
            text = tostring(p.count), x = bounds.x + bounds.width - padding
                - backend.measureText(tostring(p.count), font),
            y = bounds.y + bounds.height - padding - font.lineHeight,
            font = font, clip = effectiveClip,
            state = p.semanticState or "none", ordinal = plan.ordinal }
    end
    if p.iconId ~= nil then
        if profile.icons == nil or profile.icons[p.iconId] == nil then
            error("missing icon mapping")
        end
        plan.primitives[#plan.primitives + 1] = { kind = "icon",
            icon = profile.icons[p.iconId], bounds = bounds, clip = effectiveClip,
            state = p.semanticState or "none", ordinal = plan.ordinal }
    end
    local count = #node.children
    if count > 0 then
        local inner = { x = bounds.x + padding, y = bounds.y + padding,
            width = math.max(0, bounds.width - padding * 2),
            height = math.max(0, bounds.height - padding * 2) }
        local horizontal = component == "layout.row"
            or component == "layout.split" and (p.direction or "horizontal") == "horizontal"
            or component == "control.button" or component == "control.navigationItem"
            or component == "control.listRow"
        if component == "layout.scroll" then
            local key, child = node.id or path, node.children[1]
            local measured = measureNode(child, inner.width, profile, backend)
            local vertical = (p.direction or "vertical") == "vertical"
            local contentExtent = vertical and math.max(inner.height, measured.height)
                or math.max(inner.width, measured.width)
            local viewportExtent = vertical and inner.height or inner.width
            local maximum = math.max(0, contentExtent - viewportExtent)
            session.scroll[key] = math.max(0,
                math.min(maximum, session.scroll[key] or 0))
            local childBounds = vertical
                and { x = inner.x, y = inner.y - session.scroll[key],
                    width = inner.width, height = contentExtent }
                or { x = inner.x - session.scroll[key], y = inner.y,
                    width = contentExtent, height = inner.height }
            plan.scrolls[#plan.scrolls + 1] = { id = key, bounds = effectiveClip,
                maximum = maximum, axis = p.direction or "vertical" }
            layoutNode(child, childBounds, effectiveClip, profile, backend,
                session, plan, path .. ".1")
        else
            local available = math.max(0,
                (horizontal and inner.width or inner.height) - gap * (count - 1))
            local measured, fixed, totalWeight = {}, 0, 0
            for index, child in ipairs(node.children) do
                measured[index] = measureNode(child, inner.width, profile, backend)
                local mode = horizontal and (child.properties.widthMode or "auto")
                    or (child.properties.heightMode or "auto")
                if mode == "fill" or mode == "weighted" then
                    totalWeight = totalWeight + (child.properties.grow or 1)
                else
                    fixed = fixed + (horizontal and measured[index].width
                        or measured[index].height)
                end
            end
            local remaining = math.max(0, available - fixed)
            local extents, occupied = {}, 0
            for index, child in ipairs(node.children) do
                local mode = horizontal and (child.properties.widthMode or "auto")
                    or (child.properties.heightMode or "auto")
                local extent = (mode == "fill" or mode == "weighted")
                    and remaining * (child.properties.grow or 1) / math.max(1, totalWeight)
                    or (horizontal and measured[index].width or measured[index].height)
                if component == "layout.split" and totalWeight == 0 then
                    extent = available * (child.properties.grow or 1) /
                        ((node.children[1].properties.grow or 1)
                            + (node.children[2].properties.grow or 1))
                end
                local outer = requiredMetric(profile, "spacing",
                    child.properties.spacing)
                extents[index] = math.max(0, extent)
                occupied = occupied + extents[index] + outer * 2
            end
            occupied = occupied + gap * (count - 1)
            local leftover = math.max(0,
                (horizontal and inner.width or inner.height) - occupied)
            local distribution = p.distribution or "start"
            local offset = distribution == "center" and leftover / 2
                or distribution == "end" and leftover or 0
            local flowGap = gap
            if distribution == "spaceBetween" and count > 1 then
                flowGap = gap + leftover / (count - 1)
                offset = 0
            end
            local cursor = (horizontal and inner.x or inner.y) + offset
            for index, child in ipairs(node.children) do
                local outer = requiredMetric(profile, "spacing",
                    child.properties.spacing)
                cursor = cursor + outer
                local crossDesired = horizontal and measured[index].height
                    or measured[index].width
                local crossAvailable = horizontal and inner.height or inner.width
                local alignment = p.alignment or "start"
                local crossExtent = alignment == "stretch" and crossAvailable
                    or math.min(crossAvailable, crossDesired)
                local crossOffset = alignment == "center"
                        and (crossAvailable - crossExtent) / 2
                    or alignment == "end" and crossAvailable - crossExtent or 0
                local childBounds = horizontal
                    and { x = cursor, y = inner.y + crossOffset,
                        width = extents[index], height = crossExtent }
                    or { x = inner.x + crossOffset, y = cursor,
                        width = crossExtent, height = extents[index] }
                layoutNode(child, childBounds, effectiveClip, profile, backend,
                    session, plan, path .. "." .. index)
                cursor = cursor + extents[index] + outer + flowGap
            end
        end
    end
    if p.actionReference ~= nil and not p.disabled then
        plan.ordinal = plan.ordinal + 1
        plan.hitRegions[#plan.hitRegions + 1] = { id = node.id or path,
            bounds = intersect(bounds, effectiveClip), action = p.actionReference,
            generation = session.generation, ordinal = plan.ordinal }
    end
end

function Renderer.createSession()
    return { contextKey = nil, safeModel = nil, generation = 0, scroll = {},
        pressed = nil, hover = nil, plan = nil }
end

function Renderer.resetSession(session)
    session.contextKey, session.safeModel, session.plan = nil, nil, nil
    session.generation, session.scroll = 0, {}
    session.pressed, session.hover = nil, nil
end

function Renderer.buildPlan(model, profile, backend, session, contextKey)
    if session.contextKey ~= contextKey then
        Renderer.resetSession(session)
        session.contextKey = contextKey
    end
    local ok, plan = pcall(function()
        session.generation = session.generation + 1
        local value = { primitives = {}, hitRegions = {}, scrolls = {},
            ordinal = 0, generation = session.generation }
        layoutNode(model.view, profile.viewport, profile.viewport, profile,
            backend, session, value, "root")
        return value
    end)
    if not ok then return nil, plan end
    session.safeModel, session.plan, session.pressed = model, plan, nil
    return plan
end

function Renderer.draw(plan, backend)
    return pcall(function()
        for _, primitive in ipairs(plan.primitives) do
            if primitive.kind == "box" then backend.drawBox(primitive)
            elseif primitive.kind == "text" then backend.drawText(primitive)
            elseif primitive.kind == "icon" then backend.drawIcon(primitive) end
        end
    end)
end

local function hit(plan, x, y)
    for index = #plan.hitRegions, 1, -1 do
        local region, b = plan.hitRegions[index], plan.hitRegions[index].bounds
        if b.width > 0 and b.height > 0 and x >= b.x and x <= b.x + b.width
            and y >= b.y and y <= b.y + b.height then return region end
    end
    return nil
end

function Renderer.pointer(session, x, y, isDown, isUp, button, activate)
    if session.plan == nil or button ~= 1 then return false end
    local target = hit(session.plan, x, y)
    if isDown then
        session.pressed = target ~= nil and { id = target.id,
            generation = target.generation, action = target.action } or nil
        return target ~= nil
    end
    if isUp then
        local pressed = session.pressed
        session.pressed = nil
        if pressed ~= nil and target ~= nil and target.id == pressed.id
            and target.generation == pressed.generation
            and equalPlain(target.action, pressed.action) then
            activate(target.action)
            return true
        end
        return pressed ~= nil
    end
    session.hover = target ~= nil and target.id or nil
    return target ~= nil
end

function Renderer.scroll(session, x, y, direction, step)
    if session.plan == nil then return false end
    for index = #session.plan.scrolls, 1, -1 do
        local scroll, b = session.plan.scrolls[index], session.plan.scrolls[index].bounds
        if x >= b.x and x <= b.x + b.width and y >= b.y and y <= b.y + b.height then
            local old = session.scroll[scroll.id] or 0
            session.scroll[scroll.id] = math.max(0,
                math.min(scroll.maximum, old + direction * step))
            return session.scroll[scroll.id] ~= old
        end
    end
    return false
end
