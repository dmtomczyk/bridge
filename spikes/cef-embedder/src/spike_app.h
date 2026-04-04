#pragma once

#include "include/cef_app.h"

class SpikeApp : public CefApp, public CefBrowserProcessHandler {
public:
    SpikeApp() = default;

    CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override { return this; }

    void OnContextInitialized() override;
    CefRefPtr<CefClient> GetDefaultClient() override;

private:
    IMPLEMENT_REFCOUNTING(SpikeApp);
};
