# Dev Feedback Widget Regression RCA

Date: March 19, 2026

## Summary

The NovaLXP feedback feature was still present as a Moodle local plugin on dev, but the visible feedback textarea no longer rendered on the front page.

The immediate cause was that the Edutor theme files on dev no longer contained the feedback integration patch required by this feature. Test and prod continued to work because their live theme code still preserved that patch.

## Expected design

This feature is not rendered by the plugin alone.

It requires both:

1. The Moodle local plugin `local/novalxpfeedback`
2. The Edutor theme patch in `patches/edutor-featured-feedback.patch`

That patch changes:

- `theme/edutor/classes/output/core_renderer.php`
- `theme/edutor/templates/fp_featured.mustache`

The patch injects `local_novalxpfeedback/widget` into featured pane 2 so the textarea appears on the front page.

## What was observed

- The feedback plugin code in this repo still contains the widget template, JS, external function, and Lambda integration.
- The current repo documentation still describes the feature as rendering in the second Edutor featured panel.
- Exported/copied Edutor theme artifacts in other NovaLXP repos do not contain the feedback patch.
- The live dev theme was in a partially patched state:
  - `fp_featured.mustache` already contained the `customcontent` render block
  - `core_renderer.php` was still missing the pane 2 widget assignment and pane data hook

## Evidence

### Required patch

The required patch is stored at:

- `patches/edutor-featured-feedback.patch`

It adds:

- `pane2customcontent` rendering in `core_renderer.php`
- `{{{customcontent}}}` output in `fp_featured.mustache`

### Unpatched dev-derived theme artifacts

The following dev-derived Edutor theme copies were inspected and were missing the feedback hook:

- `NovaLXP-Media/exports/dev/edutor-20260228-170642/edutor/classes/output/core_renderer.php`
- `NovaLXP-Media/exports/dev/edutor-20260228-170642/edutor/templates/fp_featured.mustache`
- `NovaLXP-Dashboard/artifacts/source/edutor/classes/output/core_renderer.php`
- `NovaLXP-Dashboard/artifacts/source/edutor/templates/fp_featured.mustache`

Those copies still used the standard `pane2intro` flow and did not render any `customcontent` block for pane 2.

## Root cause

The dev environment likely received a later Edutor theme refresh or artifact-based theme deployment that replaced the previously patched theme files with an unpatched Edutor snapshot.

Because the feedback widget depends on the theme patch, overwriting either of these files removed the visible feedback field even though the plugin itself remained installed:

- `theme/edutor/classes/output/core_renderer.php`
- `theme/edutor/templates/fp_featured.mustache`

## Contributing factors

- The feedback rendering dependency lived outside the plugin, inside the theme.
- Edutor theme artifacts were exported and promoted as full directory snapshots.
- Those artifact/promotion docs did not explicitly list the feedback patch as a required preserved customization.
- Later repos treated Edutor copies as authoritative theme sources without verifying that all environment-specific functional patches were still present.

## Why test and prod still worked

The most likely explanation is that test and prod still had the patched theme files in their live codebases, while dev had been refreshed from an unpatched Edutor copy later on.

## Prevention

Any future Edutor export, copy, or promotion must preserve the feedback integration patch.

Minimum checks before promoting or restoring Edutor theme files:

1. Confirm `theme/edutor/classes/output/core_renderer.php` renders `local_novalxpfeedback/widget` for pane 2.
2. Confirm `theme/edutor/templates/fp_featured.mustache` renders `customcontent`.
3. Confirm the front page on the target environment still shows the feedback textarea in featured pane 2.
4. Purge caches after deployment and retest.

## Dev repair that worked

The validated live repair on March 19, 2026 was intentionally narrow:

1. Reauthenticate AWS SSO locally with `aws sso login --profile finova-sso`
2. Connect to the Moodle host through `ssh dev-moodle-ec2`
3. Back up the live Edutor files before editing
4. Update only `theme/edutor/classes/output/core_renderer.php` because the dev template file already had the `customcontent` block
5. Confirm these live `core_renderer.php` additions exist:
   - `$pane2customcontent = $this->render_from_template(...)`
   - `local_novalxpfeedback/widget`
   - `'customcontent' => $pane2customcontent`
6. Purge caches using the host's working CLI path:

```bash
sudo -u apache php /var/www/moodle/admin/cli/purge_caches.php
```

Important environment-specific note:

- The active Moodle code lived under `/var/www/moodle/public`, but the working admin CLI path was `/var/www/moodle/admin/cli/...`, not `/var/www/moodle/public/admin/cli/...`.

## Required preservation rule

Treat the following as required Edutor customizations, not optional local edits:

- NovaLXP feedback pane 2 hook from `patches/edutor-featured-feedback.patch`
- Any active raw SCSS overrides that are intentionally controlling visible carousel behavior

If a new theme tarball or copied theme directory does not include those customizations, it must not be treated as deployable without reapplying them.
