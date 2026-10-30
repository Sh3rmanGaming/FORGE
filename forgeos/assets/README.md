# ForgeOS Presentation Assets

`phone_frame.dds` is the rounded Phone bezel promoted from the original FORGE
prototype during M2.013 polish. Its authoritative repository location is this
directory; the synchronization workflow copies it into the generated prototype
package beside the authoritative PhoneHost implementation.

`app_card.dds` is the matching rounded Phone launcher-card surface promoted
from the same prototype. It remains a visual surface only; M2 launcher cards
are read-only and do not execute applications or controllers.

The asset is presentation-only. It does not define Phone lifecycle, input,
visibility, application, notification, or navigation behaviour.

## Attention badge images (PF.005)

`badge_unread_circle.png`, `badge_unread_pill.png`, `badge_attention.png`,
`badge_warning.png`, and `badge_error.png` are the application attention badge
shapes: a white, anti-aliased, rounded shape with any glyph baked in near black.
The Hosts tint them at draw time with the semantic colour for the state, so the
images themselves carry no colour meaning.

They are generated, not hand-drawn. `tools/generate_badge_assets.py` rebuilds
them deterministically with no outside imaging library, and
`tools/tests/test_generate_badge_assets.py` fails if a committed image differs
from the generator. Change the generator and regenerate to alter a badge; do not
edit the PNG files directly.

Like the other assets here, they are presentation-only and define no attention
truth. If an image cannot be created the Hosts fall back to flat rectangles.
