# Git Setup

Dual remote setup:
- `origin` - private work repo (UKGEPIC/elita.git) via SSH
- `public` - public repo (limadelic/elita.git) via HTTPS

Sync both:
```bash
git push origin main    # to private
git push https://limadelic:$GITHUB_PUBLIC_TOKEN@github.com/limadelic/elita.git main    # to public
```

Pull from either:
```bash
git pull origin main    # from private
git pull public main    # from public
```

# Code Styles

- use single words ALWAYS (no compound words)
- import module functions instead of calling Module.func (only import what you use)
- remove all parenths that can b removed (keep where syntax requires)
- prefer multiple small functions with pattern matching over nested case statements
- use pipeline flow with |> for data transformation
- extract anonymous functions into named functions for clarity