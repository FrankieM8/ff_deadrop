UIBridge = UIBridge or {}

function UIBridge.Notify(data)
    lib.notify(data)
end

function UIBridge.ShowTextUI(text)
    lib.showTextUI(text)
end

function UIBridge.HideTextUI()
    lib.hideTextUI()
end

function UIBridge.ProgressCircle(data)
    return lib.progressCircle(data)
end
