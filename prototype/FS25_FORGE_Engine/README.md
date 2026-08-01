# FORGE Engine 0.4.0.0

This development build introduces the first data-driven campaign and project layer.

## Test
1. Install the ZIP as `FS25_FORGE_Engine.zip`.
2. Enable FORGE Engine on the test career.
3. Press F7.
4. Open **Projects**.
5. Confirm that **Welcome to FORGE** is displayed with its current stage and objectives.
6. Save, exit, and reload.
7. Confirm `forge.xml` contains a `campaigns` section and the Projects app still loads.

Project definitions are loaded from:

`config/campaigns.xml`

The included example campaign is:

`config/campaigns/forge_tutorial/campaign.xml`
