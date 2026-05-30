# TODO

Hosting
- [x] Super basic setup
- [x] CI/CD to deploy
- [x] Basic hosting of the application
- [x] Basic login system
- [ ] Get a domain and route it to website

- [x] Welcome page
- [ ] Leaderboard
    - [ ] Leaderboard view on home page
    - [ ] Store points for every event

Side Quests
- [ ] Riddles
    - [ ] Find 3 riddles
- [ ] Scavenger hunt
Maybe points?
- [ ] Sword fighting
- [ ] Mystic arts

Events
- [ ] Market (add instructions)
- [ ] Performance lineup
- [ ] Potluck
- [ ] Donations + Charity (cash + etransfer)

Main Quests
- [ ] Potion Quiz
- [ ] Archery
- [ ] Hobby horse races
- [ ] King's court jousting (bracket generator)

- [ ] Costume voting

Tournament
- Points accumulated over other events
- Leaderboard style
- Winners will go into the final tournament

---

## Deployment

The app is configured to deploy to [Fly.io](https://fly.io). A `Dockerfile` and GitHub Actions workflow (`.github/workflows/deploy.yml`) are already set up. You just need to do the one-time Fly.io setup below.

### Data persistence

The app uses Storail (file-based JSON) at `./data` inside the container. This data is wiped on every redeploy. To persist data across deploys, create a Fly.io volume and mount it:

```sh
fly volumes create rennyaysance_data --size 1
```

Then add to `fly.toml`:

```toml
[mounts]
  source = "rennyaysance_data"
  destination = "/app/data"
```

---

### Useful commands

```sh
fly logs        # View logs
fly logs -f     # Tail logs in real time
fly status      # Check machine status
fly ssh console # SSH into the running container
```
