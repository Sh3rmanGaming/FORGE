-- FORGE Campaign Manager
-- Loads data-driven campaigns and exposes project state to FORGE OS.

ForgeCampaignManager = {
    VERSION = "0.1.0.0",
    SAVE_SECTION = "campaigns",
    campaigns = {},
    campaignOrder = {},
    activeCampaignId = nil,
    activeProjectId = nil
}

local function boolValue(value, default)
    if value == nil then
        return default == true
    end
    return value == true or value == "true" or value == "1"
end

local function normalisePath(path)
    path = tostring(path or "")
    path = string.gsub(path, "\\", "/")
    return path
end

function ForgeCampaignManager:clear()
    self.campaigns = {}
    self.campaignOrder = {}
    self.activeCampaignId = nil
    self.activeProjectId = nil
end

function ForgeCampaignManager:loadProject(xmlFile, projectKey)
    local project = {
        id = xmlFile:getString(projectKey .. "#id", ""),
        title = xmlFile:getString(projectKey .. "#title", "Untitled Project"),
        client = xmlFile:getString(projectKey .. "#client", ""),
        description = xmlFile:getString(projectKey .. "#description", ""),
        initialStatus = xmlFile:getString(projectKey .. "#initialStatus", "OFFERED"),
        status = xmlFile:getString(projectKey .. "#initialStatus", "OFFERED"),
        currentStage = 1,
        stages = {}
    }

    local stageIndex = 0
    while true do
        local stageKey = string.format("%s.stages.stage(%d)", projectKey, stageIndex)
        if not xmlFile:hasProperty(stageKey) then
            break
        end

        local stage = {
            id = xmlFile:getString(stageKey .. "#id", tostring(stageIndex + 1)),
            title = xmlFile:getString(stageKey .. "#title", "Stage " .. tostring(stageIndex + 1)),
            description = xmlFile:getString(stageKey .. "#description", ""),
            objectives = {}
        }

        local objectiveIndex = 0
        while true do
            local objectiveKey = string.format("%s.objectives.objective(%d)", stageKey, objectiveIndex)
            if not xmlFile:hasProperty(objectiveKey) then
                break
            end

            table.insert(stage.objectives, {
                id = xmlFile:getString(objectiveKey .. "#id", tostring(objectiveIndex + 1)),
                type = xmlFile:getString(objectiveKey .. "#type", "manual"),
                text = xmlFile:getString(objectiveKey .. "#text", "Complete objective"),
                required = boolValue(xmlFile:getBool(objectiveKey .. "#required", true), true),
                completed = false
            })
            objectiveIndex = objectiveIndex + 1
        end

        table.insert(project.stages, stage)
        stageIndex = stageIndex + 1
    end

    if project.id == "" then
        ForgeLogger.warning("Ignored campaign project without an id at '%s'", tostring(projectKey))
        return nil
    end

    if #project.stages == 0 then
        table.insert(project.stages, {
            id = "default",
            title = "Project Details",
            description = project.description,
            objectives = {}
        })
    end

    return project
end

function ForgeCampaignManager:loadCampaignFile(campaignId, filePath)
    if XMLFile == nil then
        ForgeLogger.error("Cannot load campaign '%s': XMLFile API unavailable", tostring(campaignId))
        return nil
    end

    local xmlFile = XMLFile.load("forgeCampaign_" .. tostring(campaignId), filePath, "campaign")
    if xmlFile == nil then
        ForgeLogger.error("Could not load campaign file '%s'", tostring(filePath))
        return nil
    end

    local campaign = {
        id = xmlFile:getString("campaign#id", campaignId),
        title = xmlFile:getString("campaign#title", campaignId),
        description = xmlFile:getString("campaign#description", ""),
        progressScope = xmlFile:getString("campaign#progressScope", "PLAYER"),
        startProject = xmlFile:getString("campaign#startProject", ""),
        projects = {},
        projectOrder = {}
    }

    local projectIndex = 0
    while true do
        local projectKey = string.format("campaign.projects.project(%d)", projectIndex)
        if not xmlFile:hasProperty(projectKey) then
            break
        end

        local project = self:loadProject(xmlFile, projectKey)
        if project ~= nil then
            campaign.projects[project.id] = project
            table.insert(campaign.projectOrder, project.id)
        end
        projectIndex = projectIndex + 1
    end

    xmlFile:delete()

    if campaign.startProject == "" then
        campaign.startProject = campaign.projectOrder[1]
    end

    ForgeLogger.info("Loaded campaign '%s' with %d project(s)", campaign.id, #campaign.projectOrder)
    return campaign
end

function ForgeCampaignManager:loadCampaignIndex()
    self:clear()

    local indexPath = ForgeEngine.MOD_DIRECTORY .. "config/campaigns.xml"
    if XMLFile == nil then
        ForgeLogger.error("Cannot load campaign index: XMLFile API unavailable")
        return false
    end

    local xmlFile = XMLFile.load("forgeCampaignIndex", indexPath, "campaigns")
    if xmlFile == nil then
        ForgeLogger.error("Could not load campaign index '%s'", tostring(indexPath))
        return false
    end

    local index = 0
    while true do
        local key = string.format("campaigns.campaign(%d)", index)
        if not xmlFile:hasProperty(key) then
            break
        end

        local enabled = xmlFile:getBool(key .. "#enabled", true)
        if enabled then
            local campaignId = xmlFile:getString(key .. "#id", "campaign_" .. tostring(index))
            local relativePath = normalisePath(xmlFile:getString(key .. "#path", ""))
            local filePath = ForgeEngine.MOD_DIRECTORY .. relativePath
            local campaign = self:loadCampaignFile(campaignId, filePath)
            if campaign ~= nil then
                self.campaigns[campaign.id] = campaign
                table.insert(self.campaignOrder, campaign.id)
            end
        end
        index = index + 1
    end

    xmlFile:delete()

    if #self.campaignOrder > 0 then
        self.activeCampaignId = self.campaignOrder[1]
        local campaign = self.campaigns[self.activeCampaignId]
        self.activeProjectId = campaign.startProject
    end

    ForgeEventBus.publish("forge.campaigns.loaded", self.campaigns)
    return #self.campaignOrder > 0
end

function ForgeCampaignManager:getActiveCampaign()
    return self.campaigns[self.activeCampaignId]
end

function ForgeCampaignManager:getActiveProject()
    local campaign = self:getActiveCampaign()
    if campaign == nil then
        return nil
    end
    return campaign.projects[self.activeProjectId]
end

function ForgeCampaignManager:getCurrentStage(project)
    project = project or self:getActiveProject()
    if project == nil then
        return nil
    end
    return project.stages[project.currentStage]
end

function ForgeCampaignManager:getProjectProgress(project)
    project = project or self:getActiveProject()
    if project == nil then
        return 0, 0, 0
    end

    local completed = 0
    local total = 0
    for _, stage in ipairs(project.stages) do
        for _, objective in ipairs(stage.objectives) do
            if objective.required then
                total = total + 1
                if objective.completed then
                    completed = completed + 1
                end
            end
        end
    end

    local percent = total > 0 and math.floor((completed / total) * 100 + 0.5) or 0
    return percent, completed, total
end

function ForgeCampaignManager:onMissionLoad()
    self:loadCampaignIndex()
    ForgeSaveManager.registerSection(self.SAVE_SECTION, self, ForgeCampaignManager.loadFromXML, ForgeCampaignManager.saveToXML)
    ForgeModuleRegistry.register("forge.campaigns", self, self.VERSION)
end

function ForgeCampaignManager:onMissionDelete()
    ForgeSaveManager.unregisterOwner(self)
    self:clear()
end

function ForgeCampaignManager:loadFromXML(xmlFile, key)
    local savedCampaignId = xmlFile:getString(key .. "#activeCampaignId", self.activeCampaignId or "")
    local savedProjectId = xmlFile:getString(key .. "#activeProjectId", self.activeProjectId or "")

    if self.campaigns[savedCampaignId] ~= nil then
        self.activeCampaignId = savedCampaignId
        local campaign = self.campaigns[savedCampaignId]
        if campaign.projects[savedProjectId] ~= nil then
            self.activeProjectId = savedProjectId
        end
    end

    for campaignId, campaign in pairs(self.campaigns) do
        for projectId, project in pairs(campaign.projects) do
            local projectKey = string.format("%s.campaign_%s.project_%s", key, campaignId, projectId)
            project.status = xmlFile:getString(projectKey .. "#status", project.status)
            project.currentStage = xmlFile:getInt(projectKey .. "#currentStage", project.currentStage)
            project.currentStage = math.max(1, math.min(#project.stages, project.currentStage))

            for stageIndex, stage in ipairs(project.stages) do
                for objectiveIndex, objective in ipairs(stage.objectives) do
                    local objectiveKey = string.format("%s.stage_%d.objective_%d#completed", projectKey, stageIndex, objectiveIndex)
                    objective.completed = xmlFile:getBool(objectiveKey, objective.completed)
                end
            end
        end
    end
end

function ForgeCampaignManager:saveToXML(xmlFile, key)
    xmlFile:setString(key .. "#activeCampaignId", self.activeCampaignId or "")
    xmlFile:setString(key .. "#activeProjectId", self.activeProjectId or "")

    for campaignId, campaign in pairs(self.campaigns) do
        for projectId, project in pairs(campaign.projects) do
            local projectKey = string.format("%s.campaign_%s.project_%s", key, campaignId, projectId)
            xmlFile:setString(projectKey .. "#status", project.status or project.initialStatus)
            xmlFile:setInt(projectKey .. "#currentStage", project.currentStage or 1)

            for stageIndex, stage in ipairs(project.stages) do
                for objectiveIndex, objective in ipairs(stage.objectives) do
                    local objectiveKey = string.format("%s.stage_%d.objective_%d#completed", projectKey, stageIndex, objectiveIndex)
                    xmlFile:setBool(objectiveKey, objective.completed == true)
                end
            end
        end
    end
end
