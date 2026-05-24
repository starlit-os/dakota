## What problem are you solving?
<!-- Write this in your own words. One paragraph. No AI. -->

- [ ] I am using an agent and I take responsibility for this PR

---

## Changes

<!-- Agent/tool-generated summary below this line is fine -->

## Testing

- [ ] `BST_FLAGS="-o x86_64_v3 true --no-interactive" just bst show --deps all oci/bluefin.bst` passes
- [ ] `just lint` passes on a built image
- [ ] `just boot-fast` or `just boot-vm` — desktop comes up, no regressions

## Checklist

- [ ] New BST elements wired into `deps.bst`
- [ ] Patches in `patches/` regenerated if junction refs changed
