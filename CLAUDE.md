# Git Setup

Dual remote setup:
- `origin` - private work repo (UKGEPIC/elita.git) via SSH
- `public` - public repo (limadelic/elita.git) via HTTPS

Sync both:
```bash
git push origin main    # to private
git push public main    # to public
```

Pull from either:
```bash
git pull origin main    # from private
git pull public main    # from public
```

# Code Styles

- use single words ALWAYS
- import module functions instead of calling Module.func
- remove all parenths that can b removed