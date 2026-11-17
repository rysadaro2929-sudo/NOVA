# Test plan

Before deployment, test on Android and desktop browsers:

1. Load the root `index.html` on GitHub Pages and verify CSS, logo and scripts load.
2. Check mobile layout, navigation, composer open/close and keyboard behavior.
3. Confirm demo interactions are clearly distinguished from server-backed actions.
4. Test authentication and each RLS policy with separate user accounts.
5. Test upload limits, MIME types, access controls and Storage policies.
6. Verify keyboard focus, labels, contrast and Khmer font rendering.
7. Check browser console and network failures before release.